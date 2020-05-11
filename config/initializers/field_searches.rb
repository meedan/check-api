Dynamic.class_eval do

  # How a field should be RENDERED ON A SEARCH FORM of a given team

  def self.field_search_json_schema_type_language(team = nil)
    languages = team.get_languages || []
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

  def self.field_search_json_schema_type_flag(_team = nil)
    keys = []
    labels = []
    DynamicAnnotation::AnnotationType.where(annotation_type: 'flag').last&.json_schema&.dig('properties', 'flags', 'required').to_a.each do |flag|
      keys << flag
      labels << I18n.t("flag_#{flag}")
    end
    values = (0..5).to_a.map(&:to_s)
    [
      { id: 'flag_name', type: 'array', title: I18n.t(:annotation_type_flag_name_label), items: { type: 'string', enum: keys, enumNames: labels } },
      { id: 'flag_value', type: 'array', title: I18n.t(:annotation_type_flag_value_label), items: { type: 'string', enum: values, enumNames: values.collect{ |v| I18n.t("flag_likelihood_#{v}") } } }
    ]
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

  def get_elasticsearch_options_dynamic_annotation_smooch
    data = { smooch: 1, indexable: self.annotated_id, id: self.annotated_id }
    { keys: [:smooch, :indexable, :id], data: data }
  end

  def get_elasticsearch_options_dynamic_annotation_flag
    flags = self.get_field_value('flags')
    keys = ['indexable'],
    data = { 'indexable' => flags.to_json }
    flags.each do |key, value|
      keys << "flag_#{key}"
      data["flag_#{key}"] = value
    end
    { keys: keys, data: data }
  end

  # How a field should be SEARCHED

  def self.languages_present_query(queries)
    { nested: { path: 'dynamics', query: { bool: { should: queries }}}}
  end

  def self.field_search_query_type_language(values, _options = nil)
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

  def self.field_search_query_type_flag_name(values, options)
    flag_names = values
    flag_values = options['flag_value'].map(&:to_i)
    queries = []
    flag_names.each do |flag_name|
      flag_values.each do |flag_value|
        queries << { term: { "dynamics.flag_#{flag_name}": flag_value } }
      end
    end
    {
      nested: {
        path: 'dynamics',
        query: {
          bool: {
            should: queries
          }
        }
      }
    }
  end
end

ProjectMedia.class_eval do
  def self.field_search_query_type_range(field, range, tzinfo, _options = nil)
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

  def self.field_search_query_type_range_created_at(range, timezone, _options = nil)
    self.field_search_query_type_range(:created_at, range, timezone)
  end

  def self.field_search_query_type_range_updated_at(range, timezone, _options = nil)
    self.field_search_query_type_range(:updated_at, range, timezone)
  end
end
