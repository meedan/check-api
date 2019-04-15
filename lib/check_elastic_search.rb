module CheckElasticSearch

  def create_elasticsearch_doc_bg(_options)
    p = self.project
    ms = MediaSearch.new
    ms.id = Base64.encode64("#{self.class.name}/#{self.id}")
    unless p.nil?
      ms.team_id = p.team_id
      ms.project_id = p.id
    end
    rtid = self.is_a?(ProjectMedia) ? (self.related_to_id || self.sources.first&.id) : nil
    ms.relationship_sources = [Digest::MD5.hexdigest(Relationship.default_type.to_json) + '_' + rtid.to_s] unless rtid.blank?
    ms.set_es_annotated(self)
    self.add_extra_elasticsearch_data(ms)
    ms.accounts = self.add_es_accounts if self.class.name == 'ProjectSource'
    ms.save!
  end

  def add_es_accounts
    ms_accounts = []
    accounts = []
    accounts = self.source.accounts unless self.source.nil?
    accounts.each do |a|
      ms_accounts << a.store_elasticsearch_data(%w(title description username), {})
    end
    ms_accounts
  end

  def update_elasticsearch_doc(keys, data = {}, obj = nil)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    options = {keys: keys, data: data}
    options[:obj] = obj unless obj.nil?
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_doc')
  end

  def update_elasticsearch_doc_bg(options)
    create_doc_if_not_exists(options)
    sleep 1
    data = get_elasticsearch_data(options[:data])
    # data.merge!(add_missing_fields(options))
    fields = {'updated_at' => Time.now.utc}
    options[:keys].each{|k| fields[k] = data[k] if !data[k].blank? }
    client = MediaSearch.gateway.client
    client.update index: CheckElasticSearchModel.get_index_alias, type: 'media_search', id: options[:doc_id], retry_on_conflict: 3,
                  body: { doc: fields }
  end

  # Keep this method until verify search feature.
  # def add_missing_fields(options)
  #   data = {}
  #   obj = options[:obj]
  #   return data unless ['ProjectMedia', 'ProjectSource'].include?(obj.class.name)
  #   unless options[:keys].include?('project_id')
  #     options[:keys] += ['team_id', 'project_id']
  #     data.merge!({project_id: obj.project_id, team_id: obj.project.team_id})
  #   end
  #   if obj.class.name == 'ProjectMedia'
  #     unless options[:keys].include?('verification_status')
  #       options[:keys] << 'verification_status'
  #       data.merge!({verification_status: obj.last_status})
  #     end
  #     unless options[:keys].include?('translation_status')
  #       options[:keys] << 'translation_status'
  #       ts = obj.annotations.where(annotation_type: "translation_status").last
  #       data.merge!({translation_status: ts.load.status}) unless ts.nil?
  #     end
  #     unless options[:keys].include?('title')
  #       options[:keys] += ['title', 'description']
  #       data.merge!({title: obj.title, description: obj.description})
  #     end
  #   end
  #   data
  # end

  def add_update_nested_obj(options)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'create_update_doc_nested')
  end

  def create_update_nested_obj_bg(options)
    return if options[:doc_id].blank?
    create_doc_if_not_exists(options)
    client = MediaSearch.gateway.client
    key = options[:nested_key]
    if options[:op] == 'create_or_update'
      field_name = 'smooch'
      source = "ctx._source.updated_at=params.updated_at;int s = 0;"+
               "for (int i = 0; i < ctx._source.#{key}.size(); i++) {"+
                 "if(ctx._source.#{key}[i].#{field_name} != null){"+
                   "ctx._source.#{key}[i].#{field_name} += params.value.#{field_name};s = 1;break;}}"+
               "if (s == 0) {ctx._source.#{key}.add(params.value)}"
    elsif options[:op] == 'create'
      source = "ctx._source.updated_at=params.updated_at;ctx._source.#{key}.add(params.value)"
    else
      source = "ctx._source.updated_at=params.updated_at;for (int i = 0; i < ctx._source.#{key}.size(); i++) { if(ctx._source.#{key}[i].id == params.id){ctx._source.#{key}[i] = params.value;}}"
    end
    values = store_elasticsearch_data(options[:keys], options[:data])
    client.update index: CheckElasticSearchModel.get_index_alias, type: 'media_search', id: options[:doc_id], retry_on_conflict: 3,
             body: { script: { source: source, params: { value: values, id: values[:id], updated_at: Time.now.utc } } }
  end

  def store_elasticsearch_data(keys, data)
    data = get_elasticsearch_data(data)
    values = { id: self.id }
    keys.each do |k|
      values[k] = data[k] unless data[k].blank?
    end
    values
  end

  def get_es_doc_obj
    self.is_annotation? ? self.annotated : self
  end

  def get_es_doc_id(obj = nil)
    obj = get_es_doc_obj if obj.nil?
    ['ProjectMedia', 'ProjectSource'].include?(obj.class.name) ? Base64.encode64("#{obj.class.name}/#{obj.id}") : nil
  end

  def doc_exists?(id)
    sleep 1
    client = MediaSearch.gateway.client
    client.exists? index: CheckElasticSearchModel.get_index_alias, type: 'media_search', id: id
  end

  def create_doc_if_not_exists(options)
    doc_id = options[:doc_id]
    ElasticSearchWorker.new.perform(YAML::dump(options[:obj]), YAML::dump({doc_id: doc_id}), 'create_doc') unless doc_exists?(doc_id)
  end

  def get_elasticsearch_data(data)
    (data.blank? and self.respond_to?(:data)) ? self.data : data
  end

  def destroy_elasticsearch_doc(data)
    begin
      client = MediaSearch.gateway.client
      client.delete index: CheckElasticSearchModel.get_index_alias, type: 'media_search', id: data[:doc_id]
    rescue
      Rails.logger.info "[ES destroy] doc with id #{data[:doc_id]} not exists"
    end
  end

  def destroy_elasticsearch_doc_nested(data)
    nested_type = data[:es_type]
    begin
      client = MediaSearch.gateway.client
      source = ''
      if self.respond_to?(:annotation_type) && self.annotation_type == 'smooch'
        field_name = 'smooch'
        source = "ctx._source.updated_at=params.updated_at;for (int i = 0; i < ctx._source.#{nested_type}.size(); i++) { if(ctx._source.#{nested_type}[i].#{field_name} != null){ctx._source.#{nested_type}[i].#{field_name} -= 1}}"

      else
        source = "ctx._source.updated_at=params.updated_at;for (int i = 0; i < ctx._source.#{nested_type}.size(); i++) { if(ctx._source.#{nested_type}[i].id == params.id){ctx._source.#{nested_type}.remove(i);}}"
      end
      client.update index: CheckElasticSearchModel.get_index_alias, type: 'media_search', id: data[:doc_id], retry_on_conflict: 3,
               body: { script: { source: source, params: { id: self.id, updated_at: Time.now.utc } } }
    rescue
      Rails.logger.info "[ES destroy] doc with id #{data[:doc_id]} not exists"
    end
  end
end
