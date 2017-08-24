class MigrateSourceAnnotations < ActiveRecord::Migration
  def change
    Annotation.where(annotated_type: 'Source').find_each do |a|
      a = a.load
      ps = ProjectSource.where(source_id: a.annotated_id).first
      unless ps.nil?
        User.current = a.annotator
        a.annotated = ps
        a.skip_check_ability = true
        a.save!
      end
    end
    User.current = nil
  end
end
