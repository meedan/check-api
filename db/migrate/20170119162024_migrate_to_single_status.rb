class MigrateToSingleStatus < ActiveRecord::Migration[4.2]
  def change
    unless defined?(Status).nil?
      ProjectMedia.all.each do |pm|
        s = Status.where(annotation_type: 'status', annotated_type: pm.class.to_s , annotated_id: pm.id).order("id asc").to_a
        # create new one with same created_at and updated_at to fix serialized issue
        # and set initial status if not exist
        unless s.first.nil?
          new_first = s.first.dup
          new_first.status = Status.default_id(pm.media, pm.project)
          new_first.created_at = pm.created_at
          new_first.updated_at = pm.updated_at
          new_first.disable_es_callbacks = true
          new_first.save!
          first = s.shift if s.first.status == Status.default_id(pm.media, pm.project)
          first.delete unless first.nil?
        end
        s.each do |obj|
          new_first.reload
          new_first.status = obj.status
          new_first.updated_at = obj.updated_at
          new_first.annotator = obj.annotator
          new_first.disable_es_callbacks = true
          new_first.save!
          obj.delete
        end
      end
    end
  end
end
