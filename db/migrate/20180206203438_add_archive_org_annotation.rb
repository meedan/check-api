class AddArchiveOrgAnnotation < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Archive Org', { 'Response' => ['JSON', false] })
  end
end
