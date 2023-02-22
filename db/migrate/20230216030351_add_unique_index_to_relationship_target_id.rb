class AddUniqueIndexToRelationshipTargetId < ActiveRecord::Migration[5.2]
  def change
    duplicates = Relationship.group(:target_id).having('COUNT(id) > 1').count
    n = duplicates.size
    i = 0
    duplicates.each do |pm_id, count|
      i += 1
      puts "[#{Time.now}] #{i}/#{n}"
      if count > 1
        relationships = Relationship.where(target_id: pm_id).to_a
        # Keep the relationship whose model is image, video or audio... if none, keep the first one
        keep = relationships.find{ |r| ['image', 'video', 'audio'].include?(r.model) } || relationships.first
        raise "No relationship to keep for target_id #{pm_id}!" if keep.nil?
        relationships.each do |relationship|
          if relationship.id == keep.id
            puts "  Keeping relationship ##{relationship.id}"
          else
            puts "  Deleting relationship ##{relationship.id}"
            relationship.destroy!
          end
        end
      end
    end

    add_index :relationships, :target_id, unique: true
  end
end
