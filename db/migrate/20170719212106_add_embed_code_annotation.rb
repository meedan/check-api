class AddEmbedCodeAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
  end
end
