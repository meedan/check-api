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

DynamicSearch.class_eval do
  attribute :location, GeoPoint
  mapping _parent: { type: 'media_search' } do
    indexes :location, type: 'geo_point'
  end
end

Dynamic.class_eval do
  def add_update_elasticsearch_dynamic_annotation_task_response_geolocation
    return if self.get_field(:response_geolocation).nil?
    location = {}
    geojson = JSON.parse(self.get_field_value(:response_geolocation))
    coordinates = geojson['geometry']['coordinates']
    indexable = geojson['properties']['name']

    if coordinates[0] != 0 || coordinates[1] != 0
      location = {
        lat: coordinates[0],
        lon: coordinates[1]
      }
    end

    data = {
      location: location,
      indexable: indexable
    }

    add_update_media_search_child('dynamic_search', [:indexable, :location], data)
  end
end
