class AddTeamTaskIndexToTasks < ActiveRecord::Migration[4.2]
  def change
    execute 'COMMIT;'
    execute %{
      CREATE OR REPLACE FUNCTION task_team_task_id(annotation_type TEXT, data TEXT)
      RETURNS INTEGER AS $team_task_id$
      DECLARE
        team_task_id INTEGER;
      BEGIN
        IF annotation_type = 'task' AND data LIKE '%team_task_id: %'
        THEN
          SELECT REGEXP_REPLACE(data, '^.*team_task_id: ([0-9]+).*$', '\\1')::int INTO team_task_id;
        ELSE
          SELECT NULL INTO team_task_id;
        END IF;
        RETURN team_task_id;
      END;
      $team_task_id$ IMMUTABLE LANGUAGE plpgsql;
    }
    execute "CREATE INDEX task_team_task_id ON annotations (task_team_task_id(annotation_type, data)) WHERE annotation_type = 'task'"
    execute 'BEGIN TRANSACTION;'
  end
end
