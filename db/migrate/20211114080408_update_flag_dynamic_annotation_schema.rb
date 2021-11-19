class UpdateFlagDynamicAnnotationSchema < ActiveRecord::Migration[5.2]
  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'flag').last
    json_schema = at.json_schema
    # add show cover field
    json_schema['properties'][:show_cover] = { type: 'boolean' }
    # adjust min and max for flags
    ["racy", "spam", "adult", "spoof", "medical", "violence"].each do |key|
      json_schema['properties']['flags']['properties'][key] = { type: 'integer', minimum: 0, maximum: 7 }
    end
    # add custom flag to existing ones
    json_schema['properties']['flags']['properties']['custom'] = { type: 'object' }
    at.json_schema = json_schema
    at.save!
  end
end
