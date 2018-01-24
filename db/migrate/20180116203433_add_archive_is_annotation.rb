class AddArchiveIsAnnotation < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Archive Is', { 'Response' => ['JSON', false] })
  end
end
