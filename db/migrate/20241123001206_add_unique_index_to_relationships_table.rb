class AddUniqueIndexToRelationshipsTable < ActiveRecord::Migration[6.1]
  def change
    # The code below is a copy-paste from the rake task lib/tasks/migrate/20230216030351_delete_duplicate_relationships.rake
    # and it's responsible for deleting any remaining duplicate relationship, but first, before running this migration, be 
    # sure to run the rake task above, with: rake check:migrate:delete_duplicate_relationships
    duplicates = Relationship.group(:target_id).having('COUNT(id) > 1').count
    n = duplicates.size
    i = 0
    duplicates.each do |pm_id, count|
      i += 1
      puts "[#{Time.now}] #{i}/#{n}"
      if count > 1
        relationships = Relationship.where(target_id: pm_id).order('id ASC').to_a
        # Keep the confirmed relationship, or the one whose model is image, video or audio... if none, keep the first one
        keep = relationships.find{ |r| r.relationship_type == Relationship.confirmed_type } || relationships.find{ |r| ['image', 'video', 'audio'].include?(r.model) } || relationships.first
        raise "No relationship to keep for target_id #{pm_id}!" if keep.nil?
        relationships.each do |relationship|
          if relationship.id == keep.id
            puts "  Keeping relationship ##{r.id}"
          else
            puts "  Deleting relationship ##{r.id}"
            relationship.destroy!
          end
          relationship.source.clear_cached_fields
          relationship.target.clear_cached_fields
        end
      end
    end

    remove_index :relationships, name: 'index_relationships_on_target_id'
    add_index :relationships, :target_id, unique: true
  end
end
