class AdjustReportDesignSchema < ActiveRecord::Migration[5.2]
  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').last
    unless at.nil?
      json_schema = at.json_schema.clone.with_indifferent_access
      options_schema = json_schema[:properties][:options][:items]
      json_schema[:properties][:options] = options_schema
      at.json_schema = json_schema
      at.save!
    end
  end
end
