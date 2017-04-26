# Define field formatters for our various dynamic field types.

DynamicAnnotation::Field.class_eval do

  def field_formatter_type_language
    begin
      I18nData.languages(I18n.locale.to_s.upcase)[self.value.upcase].capitalize
    rescue
      self.value
    end
  end

  def response_value(field_value)
    value = JSON.parse(field_value)
    answer = value['selected'] || []
    answer.insert(-1, value['other']) if !value['other'].blank?
    answer.to_sentence(locale: I18n.locale)
  end

  def field_formatter_name_response_single_choice
    response_value(self.value)
  end

  def field_formatter_name_response_multiple_choice
    response_value(self.value)
  end

end
