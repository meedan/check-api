
class GeoPoint
end

module Elasticsearch
  module Persistence
    module Model
      module Utils
        def lookup_type(type)
          mapping = {
            String => 'string',
            Integer => 'integer',
            Float => 'float',
            Date => 'date',
            Time => 'date',
            DateTime => 'date',
            Virtus::Attribute::Boolean => 'boolean',
            GeoPoint => 'geo_point'
          }
          mapping[type]
        end
      end
    end
  end
end

Dynamic.class_eval do
  def get_elasticsearch_options_dynamic_annotation_task_response_geolocation
    return {} if self.get_field(:response_geolocation).nil?
    location = {}
    geojson = JSON.parse(self.get_field_value(:response_geolocation))
    coordinates = geojson['geometry']['coordinates']
    indexable = geojson['properties']['name']

    if coordinates[0] != 0 || coordinates[1] != 0
      # re-compute long value before sending to Elasticsearch
      location = {
        lat: coordinates[0],
        lon: ((coordinates[1].to_f + 180) % 360) - 180
      }
    end

    data = {
      location: location,
      indexable: indexable
    }
    {keys: [:location, :indexable], data: data}
  end
end
