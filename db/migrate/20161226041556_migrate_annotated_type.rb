class MigrateAnnotatedType < ActiveRecord::Migration[4.2]
  def change
    Annotation.where(annotated_type: 'Media', context_type: 'Project').each do |a|
      pm = ProjectMedia.where(project_id: a.context_id, media_id: a.annotated_id).last
      unless pm.nil?
        klass = a.annotation_type.camelize.constantize
        obj = klass.find(a.id)
        obj.disable_es_callbacks = true
        obj.annotated = pm
        obj.save!
      end
    end
  end
end
