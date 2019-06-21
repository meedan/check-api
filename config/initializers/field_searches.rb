Dynamic.class_eval do

  # How a field should be RENDERED ON A SEARCH FORM of a given team
  
  def self.field_search_json_schema_type_language(team = nil)
    languages = []
    team.projects.find_each { |project| languages << project.get_languages unless project.get_languages.blank? }
    keys = languages.flatten.uniq
    include_other = true
    
    if keys.empty?
      include_other = false
      joins = "INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON a.annotated_type = 'ProjectMedia' AND pm.id = a.annotated_id INNER JOIN projects p ON pm.project_id = p.id"
      values = DynamicAnnotation::Field.group('dynamic_annotation_fields.value').where(annotation_type: 'language').joins(joins).where('p.team_id' => team.id).count.keys
      values.each do |yaml_code|
        code = YAML.load(yaml_code)
        keys << code
      end
    end
    
    keys = keys.sort
    labels = []
    keys.each{ |code| labels << CheckCldr.language_code_to_name(code) }
    
    if include_other
      keys << "not:#{keys.join(',')}"
      labels << I18n.t(:other_language)
    end

    keys << "und"
    labels << I18n.t(:unidentified_language)

    { type: 'array', title: I18n.t(:annotation_type_language_label), items: { type: 'string', enum: keys, enumNames: labels } }
  end

  def self.field_sort_json_schema_type_verification_status(team = nil)
    { id: :deadline, label: I18n.t(:verification_status_deadline), asc_label: I18n.t(:verification_status_deadline_asc), desc_label: I18n.t(:verification_status_deadline_desc) } unless team.get_status_target_turnaround.blank?
  end

  def self.field_sort_json_schema_type_smooch(_team = nil)
    { id: :smooch, label: I18n.t(:smooch_requests), asc_label: I18n.t(:smooch_requests_asc), desc_label: I18n.t(:smooch_requests_desc) }
  end

  # How a field should be INDEXED BY ELASTICSEARCH
  
  def get_elasticsearch_options_dynamic_annotation_verification_status
    deadline = self.get_field_value(:deadline).to_i
    data = { deadline: deadline, indexable: deadline }
    { keys: [:deadline, :indexable], data: data }
  end
  
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

  def get_elasticsearch_options_dynamic_annotation_smooch
    data = { smooch: 1, indexable: self.annotated_id, id: self.annotated_id }
    { keys: [:smooch, :indexable, :id], data: data }
  end

  # How a field should be SEARCHED

  def self.languages_present_query(queries)
    { nested: { path: 'dynamics', query: { bool: { should: queries }}}}
  end

  def self.field_search_query_type_language(values)
    bool = []
    other = values.select{ |v| v =~ /^not:/ }.last
    unidentified = values.select{ |v| v == 'und' }
    values -= [other, unidentified]

    field_language_exists = { nested: { path: "dynamics", query: { exists: { field: "dynamics.language" }}}}

    if other
      langs = other.gsub('not:', '').split(',')
      langs << 'und'
      queries = []
      langs.each do |value|
        queries << { term: { "dynamics.language": value } }
      end
      unless queries.empty?
        bool << {
          bool: {
            must: field_language_exists,
            must_not: languages_present_query(queries)
          }
        }
      end
    end

    if !unidentified.empty?
      queries = []
      queries << { term: { "dynamics.language": 'und' } }
      bool << {
        bool: {
          should: [
            { bool: { must: languages_present_query(queries) }},
            { bool: { must_not: field_language_exists }}
          ]
        }
      }
    end

    queries = []
    values.each do |value|
      queries << { term: { "dynamics.language": value } }
    end
    unless queries.empty?
      bool << languages_present_query(queries)
    end

    { bool: { should: bool } }
  end
end

ProjectMedia.class_eval do

  def self.field_search_query_type_range(field, range, tzinfo)
    timezone = ActiveSupport::TimeZone[tzinfo] if tzinfo
    timezone = timezone ? timezone.formatted_offset : '+00:00'

    {
      range: {
        "#{field}": {
          gte: range[0].strftime("%Y-%m-%d %H:%M"),
          lte: range[1].strftime("%Y-%m-%d %H:%M"),
          format: "yyyy-MM-dd' 'HH:mm",
          time_zone: timezone
        }
      }
    }
  end

  def self.field_search_query_type_range_created_at(range, timezone)
    self.field_search_query_type_range(:created_at, range, timezone)
  end

  def self.field_search_query_type_range_updated_at(range, timezone)
    self.field_search_query_type_range(:updated_at, range, timezone)
  end

end
