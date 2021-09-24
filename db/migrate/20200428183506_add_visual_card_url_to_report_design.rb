class AddVisualCardUrlToReportDesign < ActiveRecord::Migration[4.2]
  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').last
    unless at.nil?
      json_schema = at.json_schema.clone
      json_schema['properties']['visual_card_url'] = { type: 'string', default: '' }
      at.json_schema = json_schema
      at.save!
    end
  end
end
