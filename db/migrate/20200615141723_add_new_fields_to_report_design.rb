class AddNewFieldsToReportDesign < ActiveRecord::Migration
  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').last
    unless at.nil?
      json_schema = at.json_schema.clone.with_indifferent_access
      json_schema['properties']['dark_overlay'] = { type: 'boolean', default: false }
      json_schema['properties']['language'] = { type: 'string', default: 'en' }
      at.json_schema = {
        type: 'object',
        properties: {
          state: json_schema['properties'].delete('state'),
          last_error: json_schema['properties'].delete('last_error'),
          last_published: json_schema['properties'].delete('last_published'),
          options: {
            type: 'array',
            items: json_schema
          },
        }
      }.with_indifferent_access
      at.save!

      # We need to do this in the migration, otherwise the app can be inconsistent

      n = Dynamic.where(annotation_type: 'report_design').count
      i = 0
      Dynamic.where(annotation_type: 'report_design').find_each do |report|
        i += 1
        puts "[#{Time.now}] (#{i}/#{n}) Updating report with ID #{report.id}..."
        data = report.data.with_indifferent_access
        state = data.delete(:state)
        last_error = data.delete(:last_error)
        last_published = data.delete(:last_published)
        language = report.annotated&.team&.get_language || 'en'
        report.data = {
          state: state,
          last_error: last_error.to_s,
          last_published: last_published.to_s,
          options: [data.merge({ language: language, dark_overlay: false })]
        }.with_indifferent_access
        report.save!
      end
    end
  end
end
