# Define field validators for our various dynamic field types.

DynamicAnnotation::Field.class_eval do
  def field_validator_type_geojson
    errormsg = I18n.t(:geolocation_invalid_value)
    begin
      json = JSON.parse(self.value)
      geojson = Geojsonlint.validate(json)
      errors.add(:base, errormsg) unless geojson.valid?
    rescue
      errors.add(:base, errormsg)
    end
  end

  def field_validator_type_url
    errormsg = I18n.t(:url_invalid_value)
    urls = self.value
    urls.each do |item|
      item['url'] = item['url'].strip
      url = URI.parse(item['url'])
      errors.add(:base, errormsg + ' ' + url.to_s) unless url.is_a?(URI::HTTP) && !url.host.nil?
    end
  end

  def field_validator_type_datetime
    self.value.tr!('۰١۲۳۴۵۶۷۸۹','0123456789')
    begin
      DateTime.parse(self.value)
    rescue
      errors.add(:base, I18n.t(:datetime_invalid_date))
    end
  end

  def field_validator_name_response_free_text
    schema = self.annotation&.task&.json_schema
    value = begin JSON.parse(self.value) rescue self.value end
    errors.add(:base, I18n.t(:invalid_task_answer)) if !schema.blank? && !JSON::Validator.validate(schema, value)
  end

  def field_validator_type_bot_response_format
    errormsg = I18n.t(:invalid_bot_response)
    begin
      json = JSON.parse(self.value)
      errors.add(:base, errormsg) if !json.keys.include?('title') || !json.keys.include?('description')
    rescue
      errors.add(:base, errormsg)
    end
  end

  ['free_text', 'yes_no', 'single_choice', 'multiple_choice', 'geolocation', 'datetime', 'file_upload', 'number'].each do |type|
    define_method "field_validator_name_suggestion_#{type}" do
      errormsg = I18n.t(:task_suggestion_invalid_value)
      begin
        json = JSON.parse(self.value)
        errors.add(:base, errormsg) if json.keys != ['suggestion', 'comment']
      rescue
        errors.add(:base, errormsg)
      end
    end

    ['review'].each do |action|
      define_method "field_validator_name_#{action}_#{type}" do
        errors.add(:base, I18n.t("bot_cant_add_#{action}_to_task")) if !self.value.blank? && User.current.present? && User.current.type == 'BotUser'
      end
    end
  end
end
