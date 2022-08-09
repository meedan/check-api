Dynamic.class_eval do

  # How a field should be RENDERED ON A SEARCH FORM of a given team

  def self.field_search_json_schema_type_language(team = nil)
    languages = team.get_languages || []
    keys = languages.flatten.uniq
    include_other = true

    if keys.empty?
      include_other = false
      joins = "INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN project_medias pm ON a.annotated_type = 'ProjectMedia' AND pm.id = a.annotated_id"
      values = DynamicAnnotation::Field.group('dynamic_annotation_fields.value').where(annotation_type: 'language').joins(joins).where('pm.team_id' => team.id).count.keys
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
end

ProjectMedia.class_eval do
  def self.field_search_query_type_range(field, range, tzinfo, _options = nil)
    timezone = ActiveSupport::TimeZone[tzinfo] if tzinfo
    timezone = timezone ? timezone.formatted_offset : '+00:00'

    output  = {
      range: {
        "#{field}": {
          lte: range[1].strftime("%Y-%m-%d %H:%M"),
          format: "yyyy-MM-dd' 'HH:mm",
          time_zone: timezone
        }
      }
    }
    output[:range][:"#{field}"][:gte] = range[0].strftime("%Y-%m-%d %H:%M") if range[0].strftime("%Y").to_i > 0
    output
  end

  def self.field_search_query_type_range_long(field, range)
    {
      range: {
        "#{field}": {
          gte: range[0].to_i,
          lte: range[1].to_i
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

  def self.field_search_query_type_range_report_published_at(range, _timezone, _options = nil)
    self.field_search_query_type_range_long(:report_published_at, range)
  end

  def self.field_search_query_type_range_media_published_at(range, _timezone, _options = nil)
    self.field_search_query_type_range_long(:media_published_at, range)
  end

  def self.field_search_query_type_range_last_seen(range, _timezone, _options = nil)
    self.field_search_query_type_range_long(:last_seen, range)
  end
end
