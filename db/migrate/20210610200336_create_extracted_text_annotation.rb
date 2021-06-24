require 'sample_data'
include SampleData

class CreateExtractedTextAnnotation < ActiveRecord::Migration
  def change
    json_schema = {
      type: 'object',
      required: ['text'],
      properties: {
        text: { type: 'string' }
      }
    }
    create_annotation_type_and_fields('Extracted Text', {}, json_schema)
  end
end
