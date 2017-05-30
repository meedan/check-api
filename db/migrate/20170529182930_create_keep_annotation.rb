class CreateKeepAnnotation < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Keep Backup', { 'Response' => ['JSON', false] })
  end
end
