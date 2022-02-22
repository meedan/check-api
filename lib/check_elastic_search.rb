module CheckElasticSearch

  def create_elasticsearch_doc_bg(_options)
    doc_id = Base64.encode64("#{self.class.name}/#{self.id}")
    return if doc_exists?(doc_id)
    ms = ElasticItem.new
    ms.attributes[:id] = doc_id
    # TODO: Sawy remove annotation_type field
    ms.attributes[:annotation_type] = 'mediasearch'
    ms.attributes[:team_id] = self.team_id
    ms.attributes[:project_id] = self.project_id
    ms.attributes[:annotated_type] = self.class.name
    ms.attributes[:annotated_id] = self.id
    ms.attributes[:parent_id] = self.id
    ms.attributes[:created_at] = self.created_at.utc
    ms.attributes[:updated_at] = self.updated_at.utc
    ms.attributes[:media_published_at] = self.media_published_at
    ms.attributes[:source_id] = self.source_id
    # Intial nested objects with []
    ['accounts', 'comments', 'tags', 'dynamics', 'task_responses', 'task_comments', 'assigned_user_ids'].each{ |f| ms.attributes[f] = [] }
    self.add_extra_elasticsearch_data(ms)
    $repository.save(ms)
    $repository.refresh_index! if CheckConfig.get('elasticsearch_sync')
  end

  def update_elasticsearch_doc(keys, data = {}, obj = nil)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    options = { keys: keys, data: data }
    options[:obj] = obj unless obj.nil?
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_doc')
  end

  def update_elasticsearch_doc_bg(options)
    data = get_elasticsearch_data(options[:data])
    fields = { 'updated_at' => Time.now.utc }
    options[:keys].each do |k|
      unless data[k].nil?
        if data[k].class.to_s == 'Hash'
          value = get_fresh_value(data[k].with_indifferent_access)
          fields[k] = value unless value.nil?
        else
          fields[k] = data[k]
        end
      end
    end
    if fields.count > 1
      create_doc_if_not_exists(options)
      sleep 1
      client = $repository.client
      client.update index: CheckElasticSearchModel.get_index_alias, id: options[:doc_id], retry_on_conflict: 3, body: { doc: fields }
    end
  end

  # Get a fresh data based on data(Hash)
  def get_fresh_value(data)
    value = nil
    klass = data['klass']
    obj = klass.constantize.find_by_id data['id'] unless klass.blank?
    unless obj.nil?
      callback = data['method']
      value = obj.send(callback) if !callback.blank? && obj.respond_to?(callback)
      value = value.to_i if data['type'] == 'int'
    end
    value
  end

  def add_update_nested_obj(options)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'create_update_doc_nested')
  end

  def create_update_nested_obj_bg(options)
    return if options[:doc_id].blank?
    create_doc_if_not_exists(options)
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
    client = $repository.client
    client.update index: CheckElasticSearchModel.get_index_alias, id: options[:doc_id], retry_on_conflict: 3,
            body: { script: { source: source, params: { value: values, id: values['id'], updated_at: Time.now.utc } } }
  end

  def store_elasticsearch_data(keys, data)
    data = get_elasticsearch_data(data)
    values = { 'id' => self.id }
    keys.each do |k|
      values[k] = data[k] unless data[k].blank?
    end
    values
  end

  def get_es_doc_obj
    obj = self.is_annotation? ? self.annotated : self
    obj.class.name == 'Cluster' ? obj.project_media : obj
  end

  def get_es_doc_id(obj = nil)
    obj = get_es_doc_obj if obj.nil?
    obj.class.name == 'ProjectMedia' ? Base64.encode64("#{obj.class.name}/#{obj.id}") : nil
  end

  def doc_exists?(id)
    sleep 1
    $repository.exists?(id)
  end

  def create_doc_if_not_exists(options)
    doc_id = options[:doc_id]
    ElasticSearchWorker.new.perform(YAML::dump(options[:obj]), YAML::dump({doc_id: doc_id}), 'create_doc') unless doc_exists?(doc_id)
  end

  def get_elasticsearch_data(data)
    responses_data = get_data_for_responses_fields
    data = responses_data unless responses_data.blank?
    (data.blank? and self.respond_to?(:data)) ? self.data : data
  end

  def get_data_for_responses_fields
    # this method to get data for task_responses field
    data = {}
    if self.class.name == 'Dynamic' && self.annotation_type =~ /^task_response/
      # get value for choice and free text fields
      field_name = self.annotation_type.sub(/task_/, '')
      field = self.get_field(field_name)
      unless field.nil?
        if field.field_name =~ /choice/
          value = field.selected_values_from_task_answer
        else
          value = [field.value]
        end
        data = { value: value, field_type: field.field_type }
        data.merge!({ date_value: DateTime.parse(field.value).utc }) if field.field_name =~ /datetime/
        data.merge!({ numeric_value: field.value.to_i }) if field.field_name =~ /number/
        task = self.annotated
        if task.respond_to?(:annotation_type) && task.annotation_type == 'task'
          data.merge!({ id: task.id, team_task_id: task.team_task_id, fieldset: task.fieldset })
        end
      end
    end
    data.with_indifferent_access
  end

  def destroy_elasticsearch_doc(data)
    begin
      $repository.delete(data[:doc_id])
    rescue
      Rails.logger.info "[ES destroy] doc with id #{data[:doc_id]} not exists"
    end
  end

  def destroy_elasticsearch_doc_nested(data)
    nested_type = data[:es_type]
    begin
      client = $repository.client
      source = ''
      if self.respond_to?(:annotation_type) && self.annotation_type == 'smooch'
        field_name = 'smooch'
        source = "ctx._source.updated_at=params.updated_at;for (int i = 0; i < ctx._source.#{nested_type}.size(); i++) { if(ctx._source.#{nested_type}[i].#{field_name} != null){ctx._source.#{nested_type}[i].#{field_name} -= 1}}"

      else
        source = "ctx._source.updated_at=params.updated_at;for (int i = 0; i < ctx._source.#{nested_type}.size(); i++) { if(ctx._source.#{nested_type}[i].id == params.id){ctx._source.#{nested_type}.remove(i);}}"
      end
      client.update index: CheckElasticSearchModel.get_index_alias, id: data[:doc_id], retry_on_conflict: 3,
               body: { script: { source: source, params: { id: self.id, updated_at: Time.now.utc } } }
    rescue
      Rails.logger.info "[ES destroy] doc with id #{data[:doc_id]} not exists"
    end
  end
end
