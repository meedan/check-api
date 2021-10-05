require 'sample_data'
include SampleData

class AddFetchAnnotation < ActiveRecord::Migration[4.2]
  def change
    json_schema = {
      type: 'object',
      required: ['id'],
      properties: {
        id: { type: 'string' }
      }
    }
    create_annotation_type_and_fields('Fetch', {}, json_schema)
  end
end
