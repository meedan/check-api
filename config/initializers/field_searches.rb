Dynamic.class_eval do

  # How a field should be RENDERED ON A SEARCH FORM of a given team
  
  def self.field_search_json_schema_type_language(team = nil)
    joins = "INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON a.annotated_type = 'ProjectMedia' AND pm.id = a.annotated_id INNER JOIN projects p ON pm.project_id = p.id"
    values = DynamicAnnotation::Field.group('dynamic_annotation_fields.value').where(annotation_type: 'language').joins(joins).where('p.team_id' => team.id).count.keys
    keys = []
    labels = []
    values.each do |yaml_code|
      code = YAML.load(yaml_code)
      keys << code
      labels << CheckCldr.language_code_to_name(code)
    end
    { type: 'array', title: I18n.t(:annotation_type_language_label), items: { type: 'string', enum: keys, enumNames: labels } }
  end

  # How a field should be INDEXED BY ELASTICSEARCH
  
  def get_elasticsearch_options_dynamic_annotation_language
    code = self.get_field_value(:language)
    data = { language: code, indexable: code }
    { keys: [:language, :indexable], data: data }
  end

  def get_elasticsearch_options_dynamic_annotation_task_response_geolocation
    return {} if self.get_field(:response_geolocation).nil?
    location = {}
    geojson = JSON.parse(self.get_field_value(:response_geolocation))
    coordinates = geojson['geometry']['coordinates']
    indexable = geojson['properties']['name']

    if coordinates[0] != 0 || coordinates[1] != 0
      # re-compute long value before sending to Elasticsearch
      location = {
        lat: coordinates[0],
        lon: ((coordinates[1].to_f + 180) % 360) - 180
      }
    end

    data = {
      location: location,
      indexable: indexable
    }

    { keys: [:location, :indexable], data: data }
  end

  def get_elasticsearch_options_dynamic_annotation_task_response_datetime
    return {} if self.get_field(:response_datetime).nil?
    datetime = DateTime.parse(self.get_field_value(:response_datetime))
    data = { datetime: datetime.to_i, indexable: datetime.to_s }
    { keys: [:datetime, :indexable], data: data }
  end
end
