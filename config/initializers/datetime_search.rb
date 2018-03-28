DynamicSearch.class_eval do
  attribute :datetime, Integer
end

Dynamic.class_eval do
  def add_update_elasticsearch_dynamic_annotation_task_response_datetime
    return if self.get_field(:response_datetime).nil?
    datetime = DateTime.parse(self.get_field_value(:response_datetime))
    add_update_media_search_child('dynamic_search', [:datetime, :indexable], { datetime: datetime.to_i, indexable: datetime.to_s })
  end
end
