class AddNewFieldsToReportDesigner < ActiveRecord::Migration[4.2]
  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').last
    unless at.nil?
      json_schema = at.json_schema.clone.with_indifferent_access
      json_schema['properties']['options']['items']['properties'].merge!({
        title: { type: 'string', default: '' },
        date: { type: 'string', default: '' }
      })
      at.json_schema = json_schema
      at.save!
    end
  end
end
