class AddEmbedCodeAnnotation < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Embed Code', { 'Copied' => ['Boolean', false] })
  end
end
