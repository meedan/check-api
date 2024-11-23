class AddTriggerToRelationshipsTable < ActiveRecord::Migration[6.1]
  def up
    # Create the trigger function
    execute <<~SQL
      CREATE OR REPLACE FUNCTION validate_relationships()
      RETURNS TRIGGER AS $$
      BEGIN
          -- Check if source_id exists as a target_id
          IF EXISTS (SELECT 1 FROM relationships WHERE target_id = NEW.source_id) THEN
              RAISE EXCEPTION 'source_id % already exists as a target_id', NEW.source_id;
          END IF;

          -- Check if target_id exists as a source_id
          IF EXISTS (SELECT 1 FROM relationships WHERE source_id = NEW.target_id) THEN
              RAISE EXCEPTION 'target_id % already exists as a source_id', NEW.target_id;
          END IF;

          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    # Attach the trigger to the table (only on INSERT - we shouldn't have it for UPDATE since we need to support reverting a relationship
    execute <<~SQL
      CREATE TRIGGER enforce_relationships
      BEFORE INSERT ON relationships
      FOR EACH ROW
      EXECUTE FUNCTION validate_relationships();
    SQL
  end

  def down
    # Remove the trigger and function if rolling back
    execute "DROP TRIGGER IF EXISTS enforce_relationships ON relationships;"
    execute "DROP FUNCTION IF EXISTS validate_relationships();"
  end
end
