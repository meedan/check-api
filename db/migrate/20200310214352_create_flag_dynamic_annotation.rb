require 'sample_data'
include SampleData

class CreateFlagDynamicAnnotation < ActiveRecord::Migration[4.2]
  def change
    json_schema = {
      type: 'object',
      required: ['flags'],
      properties: {
        flags: {
          type: 'object',
          required: ['adult', 'spoof', 'medical', 'violence', 'racy', 'spam'],
          properties: {
            adult: { type: 'integer', minimum: 0, maximum: 5 },
            spoof: { type: 'integer', minimum: 0, maximum: 5 },
            medical: { type: 'integer', minimum: 0, maximum: 5 },
            violence: { type: 'integer', minimum: 0, maximum: 5 },
            racy: { type: 'integer', minimum: 0, maximum: 5 },
            spam: { type: 'integer', minimum: 0, maximum: 5 }
          }
        }
      }
    }
    DynamicAnnotation::AnnotationType.reset_column_information
    create_annotation_type_and_fields('Flag', {}, json_schema)
  end
end
