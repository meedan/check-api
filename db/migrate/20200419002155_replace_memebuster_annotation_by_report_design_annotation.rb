require 'sample_data'
include SampleData

class ReplaceMemebusterAnnotationByReportDesignAnnotation < ActiveRecord::Migration[4.2]
  def change
    json_schema = {
      type: 'object',
      properties: {
        state: { type: 'string', default: 'paused' },
        use_introduction: { type: 'boolean', default: false },
        introduction: { type: 'string', default: '' },
        use_visual_card: { type: 'boolean', default: false },
        image: { type: 'string', default: '' },
        headline: { type: 'string', default: '' },
        description: { type: 'string', default: '' },
        status_label: { type: 'string', default: '' },
        previous_published_status_label: { type: 'string', default: '' },
        theme_color: { type: 'string', default: '' },
        url: { type: 'string', default: '' },
        use_text_message: { type: 'boolean', default: false },
        text: { type: 'string', default: '' },
        use_disclaimer: { type: 'boolean', default: false },
        disclaimer: { type: 'string', default: '' },
        last_error: { type: 'string', default: '' },
        last_published: { type: 'string', default: '' }
      }
    }
    DynamicAnnotation::AnnotationType.reset_column_information
    create_annotation_type_and_fields('Report Design', {}, json_schema)
  end
end
