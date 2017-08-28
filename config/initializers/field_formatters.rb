# Define field formatters for our various dynamic field types.

DynamicAnnotation::Field.class_eval do

  def field_formatter_type_language
    code = self.value.to_s.downcase
    CheckCldr.language_code_to_name(code)
  end

  def field_formatter_name_response_single_choice
    response_value(self.value)
  end

  def field_formatter_name_response_multiple_choice
    response_value(self.value)
  end

  def field_formatter_mt_mt_translations
    response = JSON.parse(self.value)
    return [] if response.blank?
    response.each{|v| v['lang_name'] = CheckCldr.language_code_to_name(v['lang'])}
    response
  end

  def field_formatter_name_translation_status_status
    self.value.titleize
  end

  def field_formatter_type_geojson
    geojson = JSON.parse(self.value)
    value = geojson['properties']['name']
    coordinates = geojson['geometry']['coordinates']
    if coordinates[0].to_i != 0 || coordinates[1].to_i != 0
      value += " (#{coordinates[0]}, #{coordinates[1]})"
    end
    value
  end

  def field_formatter_type_datetime
    I18n.l(DateTime.parse(self.value), format: :task)
  end

  private

  def response_value(field_value)
    value = nil
    begin
      value = JSON.parse(field_value)
    rescue JSON::ParserError
      return field_value
    end
    answer = value['selected'] || []
    answer.insert(-1, value['other']) if !value['other'].blank?
    answer.to_sentence(locale: I18n.locale)
  end
end
