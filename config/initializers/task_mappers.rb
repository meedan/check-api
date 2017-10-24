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
      begin
        date = Time.zone.parse(date)
        date = date.strftime("%Y-%m-%d %I:%M %z %Z")
      rescue
        date = ''
      end
    end
    date
  end

end
