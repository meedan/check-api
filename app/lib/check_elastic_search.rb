require 'active_support/concern'

module CheckElasticSearch
  extend ActiveSupport::Concern

  def create_elasticsearch_doc_bg(options)
    doc_id = Base64.encode64("#{self.class.name}/#{self.id}")
    is_exist = doc_exists?(doc_id)
    return if is_exist && !options[:force_creation]
    if is_exist && options[:force_creation]
      ms = $repository.find(doc_id)
      $repository.delete(ms)
    end
    ms = ElasticItem.new
    ms.attributes[:id] = doc_id
    # TODO: Sawy remove annotation_type field
    ms.attributes[:annotation_type] = 'mediasearch'
    ms.attributes[:team_id] = self.team_id
    ms.attributes[:annotated_type] = self.class.name
    ms.attributes[:annotated_id] = self.id
    ms.attributes[:parent_id] = self.id
    ms.attributes[:created_at] = self.created_at.utc
    ms.attributes[:updated_at] = self.updated_at.utc
    ms.attributes[:source_id] = self.source_id
    # Intial nested objects with []
    ['tags', 'task_responses', 'assigned_user_ids', 'requests'].each{ |f| ms.attributes[f] = [] }
    self.add_nested_objects(ms) if options[:force_creation]
    self.add_extra_elasticsearch_data(ms)
    $repository.save(ms)
    $repository.refresh_index! if CheckConfig.get('elasticsearch_sync')
  end

  def update_elasticsearch_doc(keys, data = {}, pm_id = nil, skip_get_data = false)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    options = { keys: keys, data: data, pm_id: pm_id, skip_get_data: skip_get_data }
    model = { klass: self.class.name, id: self.id }
    ElasticSearchWorker.perform_in(1.second, YAML::dump(model), YAML::dump(options), 'update_doc')
  end

  def update_recent_activity(obj)
    # update `updated_at` date for both PG & ES
    updated_at = Time.now
    obj.update_columns(updated_at: updated_at)
    data = { updated_at: updated_at.utc }
    self.update_elasticsearch_doc(data.keys, data, obj.id, true)
  end

  def update_elasticsearch_doc_bg(options)
    data = get_elasticsearch_data(options[:data], options[:skip_get_data])
    fields = {}
    options[:keys].each do |k|
      if data[k].class.to_s == 'Hash'
        value = get_fresh_value(data[k].with_indifferent_access)
        fields[k] = value
      else
        fields[k] = data[k]
      end
    end
    if fields.count
      create_doc_if_not_exists(options)
      sleep 1
      $repository.client.update index: CheckElasticSearchModel.get_index_alias, id: options[:doc_id], body: { doc: fields }
    end
  end

  # Get a fresh data based on data(Hash)
  def get_fresh_value(data)
    value = data['default']
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
    return if options[:op] == 'create' && self.respond_to?(:hit_nested_objects_limit?) && self.hit_nested_objects_limit?
    model = { klass: self.class.name, id: self.id }
    ElasticSearchWorker.perform_in(1.second, YAML::dump(model), YAML::dump(options), 'create_update_doc_nested')
  end

  def create_update_nested_obj_bg(options)
    return if options[:doc_id].blank?
    create_doc_if_not_exists(options)
    key = options[:nested_key]
    if options[:op] == 'create'
      source = "ctx._source.#{key}.add(params.value)"
    else
      source = "for (int i = 0; i < ctx._source.#{key}.size(); i++) { if(ctx._source.#{key}[i].id == params.id){ctx._source.#{key}[i] = params.value;}}"
    end
    values = store_elasticsearch_data(options[:keys], options[:data])
    client = $repository.client
    client.update index: CheckElasticSearchModel.get_index_alias, id: options[:doc_id],
            body: { script: { source: source, params: { value: values, id: values['id'] } } }
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
    obj = obj.class.name == 'Cluster' ? obj.center : obj
    obj&.id
  end

  def get_es_doc_id(pm_id = nil)
    pm_id = get_es_doc_obj if pm_id.nil?
    pm_id.blank? ? nil : Base64.encode64("ProjectMedia/#{pm_id}")
  end

  def doc_exists?(id)
    sleep 1
    $repository.exists?(id)
  end

  def create_doc_if_not_exists(options)
    doc_id = options[:doc_id]
    model = { klass: 'ProjectMedia', id: options[:pm_id] }
    ElasticSearchWorker.new.perform(YAML::dump(model), YAML::dump({ doc_id: doc_id }), 'create_doc') unless doc_exists?(doc_id)
  end

  def get_elasticsearch_data(data, skip_get_data = false)
    responses_data = get_data_for_responses_fields unless skip_get_data
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
          value = [field.value.to_s].flatten
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

  module ClassMethods
    def destroy_elasticsearch_doc(options)
      begin
        $repository.delete(options[:doc_id])
      rescue
        Rails.logger.info "[ES destroy] doc with id #{options[:doc_id]} not exists"
      end
    end

    def destroy_elasticsearch_doc_nested(options)
      nested_type = options[:es_type]
      begin
        source = "for (int i = 0; i < ctx._source.#{nested_type}.size(); i++) { if(ctx._source.#{nested_type}[i].id == params.id){ctx._source.#{nested_type}.remove(i);}}"
        $repository.client.update index: CheckElasticSearchModel.get_index_alias, id: options[:doc_id],
                 body: { script: { source: source, params: { id: options[:model_id] } } }
      rescue
        Rails.logger.info "[ES destroy] doc with id #{options[:doc_id]} not exists"
      end
    end
  end
end
