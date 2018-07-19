Dynamic.class_eval do
  def add_update_elasticsearch_dynamic_annotation_task_response_datetime
    return if self.get_field(:response_datetime).nil?
    datetime = DateTime.parse(self.get_field_value(:response_datetime))
    data = { datetime: datetime.to_i, indexable: datetime.to_s }
    add_update_nested_obj({op: 'create', nested_key: 'dynamics', keys: [:datetime, :indexable], data: data})
  end
end
