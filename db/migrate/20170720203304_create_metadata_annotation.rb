class CreateMetadataAnnotation < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Metadata', { 'Value' => ['JSON', false] })
  end
end
