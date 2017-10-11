module CheckElasticSearch

  def update_media_search(keys, data = {}, parent = nil)
    return if self.disable_es_callbacks
    options = {keys: keys, data: data}
    options[:parent] = parent unless parent.nil?
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_parent')
  end

  def update_media_search_bg(options)
    ms = get_elasticsearch_parent(options[:parent])
    unless ms.nil?
      data = get_elasticsearch_data(options[:data])
      fields = {'last_activity_at' => Time.now.utc}
      options[:keys].each{|k| fields[k] = data[k] if ms.respond_to?("#{k}=") and !data[k].blank? }
      ms.update fields
    end
  end

  def add_update_media_search_child(child, keys, data = {}, parent = nil)
    return if self.disable_es_callbacks
    options = {keys: keys, data: data}
    options[:parent] = parent unless parent.nil?
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), child)
  end

  def add_update_media_search_child_bg(child, options)
    # get parent
    ms = get_elasticsearch_parent(options[:parent])
    unless ms.nil?
      child = child.singularize.camelize.constantize
      model = child.search(query: { match: { _id: self.id } }).results.last
      if model.nil?
        model = child.new
        model.id = self.id
      end
      store_elasticsearch_data(model, options[:keys], options[:data], {parent: ms.id})
      # Update last_activity_at on parent
      ms.update last_activity_at: Time.now.utc
    end
  end

  def store_elasticsearch_data(model, keys, data, options = {})
    data = get_elasticsearch_data(data)
    keys.each do |k|
      model.send("#{k}=", data[k]) if model.respond_to?("#{k}=") and !data[k].blank?
    end
    model.save!(options)
  end

  def get_parent_id
    if self.is_annotation?
      pm = get_es_parent_id(self.annotated_id, self.annotated_type)
    else
      pm = get_es_parent_id(self.id, self.class.name)
    end
    pm
  end

  def get_es_parent_id(id, klass)
    (klass == 'ProjectSource') ? Base64.encode64("ProjectSource/#{id}") : id
  end

  def get_elasticsearch_parent(parent)
    sleep 1 if Rails.env == 'test'
    MediaSearch.search(query: { match: { _id: parent } }).last unless parent.nil?
  end

  def get_elasticsearch_data(data)
    (data.blank? and self.respond_to?(:data)) ? self.data : data
  end

  def destroy_elasticsearch_data(model, type = 'child')
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    options = {}
    if type == 'child'
      options = {parent: get_parent_id}
      id = self.id
    else
      id = get_parent_id
    end
    obj = model.search(query: { match: { _id: id } }).last
    obj.delete(options) unless obj.nil?
  end

end
