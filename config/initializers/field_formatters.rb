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
