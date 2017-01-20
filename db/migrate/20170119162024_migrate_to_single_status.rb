class MigrateToSingleStatus < ActiveRecord::Migration
  def change
    ProjectMedia.all.each do |pm|
      s = Status.where(annotation_type: 'status', annotated_type: pm.class.to_s , annotated_id: pm.id).to_a
      first = s.pop
      s.reverse.each do |obj|
        first.status = obj.status
        first.updated_at = obj.updated_at
        first.save!
        obj.delete
      end
    end
  end
end
