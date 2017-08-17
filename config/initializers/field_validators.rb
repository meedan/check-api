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
end
