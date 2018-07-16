module CheckElasticSearch

  def update_media_search(keys, data = {}, parent = nil)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    options = {keys: keys, data: data}
    options[:obj] = parent unless parent.nil?
    # ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_parent')
    ElasticSearchWorker.new.perform(YAML::dump(self), YAML::dump(options), 'update_parent')
  end

  def add_media_search_bg
    p = self.project
    ms = MediaSearch.new
    ms.id = Base64.encode64("#{self.class.name}/#{self.id}")
    ms.team_id = p.team.id
    ms.project_id = p.id
    rtid = self.is_a?(ProjectMedia) ? (self.related_to_id || self.sources.first&.id) : nil
    ms.relationship_sources = [Digest::MD5.hexdigest(Relationship.default_type.to_json) + '_' + rtid.to_s] unless rtid.blank?
    ms.set_es_annotated(self)
    self.add_extra_elasticsearch_data(ms)
    ms.save!
  end

  def update_media_search_bg(options)
    create_doc_if_not_exists(options)
    data = get_elasticsearch_data(options[:data])
    fields = {}
    options[:keys].each{|k| fields[k] = data[k] if !data[k].blank? }
    client = MediaSearch.gateway.client
    client.update index: CheckElasticSearchModel.get_index_alias, type: 'media_search', id: options[:doc_id],
                  body: { doc: fields }
  end

  # def add_missing_fields(options)
  #   data = {}
  #   parent = options[:parent]
  #   return data unless ['ProjectMedia', 'ProjectSource'].include?(parent.class.name)
  #   unless options[:keys].include?('project_id')
  #     options[:keys] += ['team_id', 'project_id']
  #     data.merge!({project_id: parent.project_id, team_id: parent.project.team_id})
  #   end
  #   if parent.class.name == 'ProjectMedia'
  #     unless options[:keys].include?('status')
  #       options[:keys] << 'status'
  #       data.merge!({status: parent.last_status})
  #     end
  #     unless options[:keys].include?('title')
  #       options[:keys] += ['title', 'description']
  #       data.merge!({title: parent.title, description: parent.description})
  #     end
  #   end
  #   data
  # end

  def add_nested_obj(nested_key, keys, data = {}, obj = nil)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    options = {keys: keys, data: data, nested_key: nested_key}
    options[:obj] = obj unless obj.nil?
    # ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_parent_nested')
    ElasticSearchWorker.new.perform(YAML::dump(self), YAML::dump(options), 'update_parent_nested')
  end

  def add_nested_obj_bg(options)
    return if options[:doc_id].blank?
    create_doc_if_not_exists(options)
    client = MediaSearch.gateway.client
    source = "ctx._source.#{options[:nested_key]}.add(params.value)"
    values = store_elasticsearch_data(options[:keys], options[:data])
    client.update index: CheckElasticSearchModel.get_index_alias, type: 'media_search', id: options[:doc_id],
             body: { script: { source: source, params: { value: values } } }
  end

  def store_elasticsearch_data(keys, data)
    data = get_elasticsearch_data(data)
    values = { id: self.id }
    keys.each do |k|
      values[k] = data[k] if self.respond_to?("#{k}=") and !data[k].blank?
    end
    values
  end

  def get_es_doc_obj
    self.is_annotation? ? self.annotated : self
  end

  def get_es_doc_id(obj = nil)
    obj = get_es_doc_obj if obj.nil?
    ['ProjectMedia', 'ProjectSource'].include?(obj.class.name) ? get_es_parent_id(obj) : nil
  end

  def get_es_parent_id(parent)
    Base64.encode64("#{parent.class.name}/#{parent.id}")
  end

  def create_doc_if_not_exists(options)
    sleep 1 if Rails.env == 'test'
    doc_id = options[:doc_id]
    unless doc_id.nil?
      client = MediaSearch.gateway.client
      unless client.exists? index: CheckElasticSearchModel.get_index_alias, type: 'media_search', id: doc_id
        ElasticSearchWorker.new.perform(YAML::dump(options[:obj]), YAML::dump({doc_id: doc_id}), 'add_parent')
      end
    end
  end

  def get_elasticsearch_data(data)
    (data.blank? and self.respond_to?(:data)) ? self.data : data
  end

  def destroy_elasticsearch_data(data)
    options = {}
    conditions = []
    parent_id = get_es_parent_id(data[:parent])
    if data[:type] == 'child'
      options = { parent: parent_id }
      id = self.id
      conditions << { has_parent: { parent_type: "media_search", query: { term: { _id: parent_id } } } }
    else
      id = parent_id
    end
    conditions << {term: { _id: id } }
    obj = data[:es_type].search(query: { bool: { must: conditions } }).last
    obj.delete(options) unless obj.nil?
  end
end
