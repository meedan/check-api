class CreateReverseImageAnnotations < ActiveRecord::Migration
  def change
    ProjectMedia.find_each do |pm|
      User.current = pm.user
      pm.send(:create_reverse_image_annotation)
      User.current = nil
    end
      
    PaperTrail::Version.where(event_type: 'create_dynamicannotationfield').where("object_after LIKE '%reverse_image_path%'").find_each do |v|
      v.created_at = v.item.annotation.annotated.created_at
      v.save
    end
  end
end
