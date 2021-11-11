class UpdateFlagDynamicAnnotationSchema < ActiveRecord::Migration[5.2]
  def change
    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'flag').last
    json_schema = at.json_schema
    # add show cover field
    json_schema['properties'][:show_cover] = { type: 'boolean' }
    # add custom flag to existing ones
    # json_schema['properties']['flags']['properties']['custom']
    at.json_schema = json_schema
    at.save!
  end
end
