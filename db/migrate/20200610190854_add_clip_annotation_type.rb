require 'sample_data'
include SampleData

class AddClipAnnotationType < ActiveRecord::Migration[4.2]
  def change
    json_schema = {
      type: 'object',
      required: ['label'],
      properties: {
        label: { type: 'string' }
      }
    }
    DynamicAnnotation::AnnotationType.reset_column_information
    create_annotation_type_and_fields('Clip', {}, json_schema)
  end
end
