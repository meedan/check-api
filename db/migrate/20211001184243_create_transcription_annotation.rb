require 'sample_data'
include SampleData

class CreateTranscriptionAnnotation < ActiveRecord::Migration[4.2]
  def change
    json_schema = {
      type: 'object',
      required: ['job_name'],
      properties: {
        text: { type: 'string' },
        job_name: { type: 'string' },
        last_response: { type: 'object' }
      }
    }
    create_annotation_type_and_fields('Transcription', {}, json_schema) unless Rails.env.test?
  end
end
