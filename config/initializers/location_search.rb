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
