require 'sample_data'
class CreateSmoochUserAnnotationType < ActiveRecord::Migration[4.2]
  include SampleData

  def change
    create_annotation_type_and_fields('Smooch User', { 'Id' => ['Text', false], 'App Id' => ['Text', false], 'Data' => ['JSON', false] })
  end
end
