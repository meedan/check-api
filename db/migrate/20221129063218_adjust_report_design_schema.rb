class AdjustReportDesignSchema < ActiveRecord::Migration[5.2]
  def change
    RequestStore.store[:skip_rules] = true

    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').last
    unless at.nil?
      json_schema = at.json_schema.clone.with_indifferent_access
      options_schema = json_schema[:properties][:options][:items]
      json_schema[:properties][:options] = options_schema
      
      at.json_schema = json_schema
      at.save!

      # We need to do this in the migration, otherwise the app can be inconsistent

      n = Dynamic.where(annotation_type: 'report_design').count
      i = 0
      Dynamic.where(annotation_type: 'report_design').find_each do |report|
        i += 1
        puts "[#{Time.now}] (#{i}/#{n}) Updating report with ID #{report.id}..."
        data = report.data.with_indifferent_access
        data[:options] = data[:options].first
        report.data = data
        report.save!
      end
    end

    RequestStore.store[:skip_rules] = false
  end
end
