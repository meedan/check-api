module CheckElasticSearch

  def update_media_search(keys, data = {})
    return if self.disable_es_callbacks
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(keys), YAML::dump(data), 'update_parent')
  end

  def update_media_search_bg(keys, data)
    ms = get_elasticsearch_parent
    unless ms.nil?
      data = get_elasticsearch_data(data)
      options = {'last_activity_at' => Time.now.utc}
      keys.each{|k| options[k] = data[k] if ms.respond_to?("#{k}=") and !data[k].blank? }
      ms.update options
    end
  end

  def add_update_media_search_child(child, keys, data = {})
    return if self.disable_es_callbacks
    ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(keys), YAML::dump(data), child)
  end

  def add_update_media_search_child_bg(child, keys, data)
    # get parent
    ms = get_elasticsearch_parent
    unless ms.nil?
      child = child.singularize.camelize.constantize
      model = child.search(query: { match: { _id: self.id } }).results.last
      if model.nil?
        model = child.new
        model.id = self.id
      end
      store_elasticsearch_data(model, keys, data, {parent: ms.id})
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

  def get_elasticsearch_parent
    pm = self.id if self.class.name == 'ProjectMedia'
    if pm.nil? and self.is_annotation?
      pm = self.annotated_id if self.annotated_type == 'ProjectMedia'
    end
    sleep 1 if Rails.env == 'test'
    MediaSearch.search(query: { match: { annotated_id: pm } }).last unless pm.nil?
  end

  def get_elasticsearch_data(data)
    (data.blank? and self.respond_to?(:data)) ? self.data : data
  end

end
