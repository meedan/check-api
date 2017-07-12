class CreateSyrianArchiveAnnotation < ActiveRecord::Migration
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Syrian Archive Data', { 'Id' => ['Id', false] })
  end
end
