class AddConstraintRelationshipSourceAndTargetMustBeDifferent < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      ALTER TABLE relationships
      ADD CONSTRAINT source_target_must_be_different
      CHECK (source_id <> target_id);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE relationships
      DROP CONSTRAINT source_target_must_be_different;
    SQL
  end  
end
