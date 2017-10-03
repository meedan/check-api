# Define task mappers.

ProjectMediaCreators.class_eval do

  def mapping_geolocation_geolocation(jsonld, mapping)
    data = JsonPath.new(mapping['match']).first(jsonld)
    {
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: data['geo'].values
      },
      properties: {
        name: data['name']
      }
    }.to_json
  end

end
