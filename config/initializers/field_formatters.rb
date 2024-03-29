# Define field formatters for our various dynamic field types.

DynamicAnnotation::Field.class_eval do

  def field_formatter_type_language
    code = self.value.to_s.downcase
    CheckCldr.language_code_to_name(code)
  end

  def field_formatter_name_response_multiple_choice
    response_value(self.value)
  end

  def field_formatter_type_geojson
    geojson = JSON.parse(self.value)
    value = geojson['properties']['name']
    coordinates = geojson['geometry']['coordinates']
    value += " (#{coordinates.join(', ')})"
    value
  end

  def field_formatter_type_url
    urls = JSON.generate(self.value)
  end

  def field_formatter_type_datetime
    # Capture TZ abbreviation manually because DateTime does not parse it
    # http://rubular.com/r/wOfJTCSxlI
    # The format string is expect to have a [TZ] placeholder to receive the abbreviation
    abbr = ''
    match = /\s([[:alpha:]]+)\s?$/.match(self.value)
    abbr = match[1] unless match.nil?
    I18n.l(DateTime.parse(self.value), format: :task).gsub('[TZ]', abbr)
  end

  ['free_text', 'yes_no', 'single_choice', 'multiple_choice', 'geolocation', 'datetime', 'file_upload', 'number', 'url'].each do |type|
    define_method "field_formatter_name_suggestion_#{type}" do
      JSON.parse(self.value)['suggestion']
    end
  end

  private

  def response_value(field_value)
    value = nil
    begin
      value = JSON.parse(field_value).to_h
    rescue
      return field_value
    end
    answer = value['selected'] || []
    answer.insert(-1, value['other']) if !value['other'].blank?
    [answer].flatten.join(', ')
  end
end
