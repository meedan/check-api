# Define task mappers.

ProjectMediaCreators.class_eval do

  def mapping_geolocation_geolocation(jsonld, mapping)
    data = mapping_value(jsonld, mapping)
    return if data.blank?
    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: data['geo'].values
      },
      properties: {
        name: mapping['prefix'] + data['name']
      }
    }.to_json
  end

  def mapping_datetime(jsonld, mapping)
    date = jsonld[mapping['match']]
    unless date.blank?
      date = Time.zone.parse(date)
      date = date.strftime("%Y-%m-%d %I:%M %z %Z")
    end
    date
  end

  private

  def mapping_value(jsonld, mapping)
    begin
      value = JsonPath.new(mapping['match']).first(jsonld)
    rescue
      value = nil
    end
    value
  end

end
