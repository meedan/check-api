Dynamic.class_eval do
  def get_elasticsearch_options_dynamic_annotation_task_response_datetime
    return {} if self.get_field(:response_datetime).nil?
    datetime = DateTime.parse(self.get_field_value(:response_datetime))
    data = { datetime: datetime.to_i, indexable: datetime.to_s }
    {keys: [:datetime, :indexable], data: data}
  end
end
