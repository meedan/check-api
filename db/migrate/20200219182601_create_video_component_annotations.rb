require 'sample_data'
include SampleData

class CreateVideoComponentAnnotations < ActiveRecord::Migration[4.2]
  def change
    create_annotation_type_and_fields('Transcript', { 'Language' => ['Language', false], 'Transcript' => ['JSON', false] })
    create_annotation_type_and_fields('Geolocation', { 'Viewport' => ['JSON', false], 'Location' => ['GeoJSON', false] })
  end
end
