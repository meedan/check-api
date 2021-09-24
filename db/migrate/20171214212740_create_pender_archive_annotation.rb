class CreatePenderArchiveAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Pender Archive', { 'Response' => ['JSON', false] })
  end
end
