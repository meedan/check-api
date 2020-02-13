require 'sample_data'
include SampleData

class CreateMetricsAnnotationAndFields < ActiveRecord::Migration
  def change
    create_annotation_type_and_fields('Metrics', { 'Data' => ['JSON', false] })
  end
end
