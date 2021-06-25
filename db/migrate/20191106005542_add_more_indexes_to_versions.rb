class AddMoreIndexesToVersions < ActiveRecord::Migration[4.2]
  def change
    execute 'COMMIT;'
    execute %{
      CREATE OR REPLACE FUNCTION version_field_name(event_type TEXT, object_after TEXT)
      RETURNS TEXT AS $name$
      DECLARE
        name TEXT;
      BEGIN
        IF event_type = 'create_dynamicannotationfield' OR event_type = 'update_dynamicannotationfield'
        THEN
          SELECT REGEXP_REPLACE(object_after, '^.*field_name":"([^"]+).*$', '\\1') INTO name;
        ELSE
          SELECT '' INTO name;
        END IF;
        RETURN name;
      END;
      $name$ IMMUTABLE LANGUAGE plpgsql;
    }
    execute %{
      CREATE OR REPLACE FUNCTION version_annotation_type(event_type TEXT, object_after TEXT)
      RETURNS TEXT AS $name$
      DECLARE
        name TEXT;
      BEGIN
        IF event_type = 'create_dynamic' OR event_type = 'update_dynamic'
        THEN
          SELECT REGEXP_REPLACE(object_after, '^.*annotation_type":"([^"]+).*$', '\\1') INTO name;
        ELSE
          SELECT '' INTO name;
        END IF;
        RETURN name;
      END;
      $name$ IMMUTABLE LANGUAGE plpgsql;
    }
    i = 0
    n = Team.count
    Team.order('id ASC').all.each do |team|
      i += 1
      partition = '"versions_partitions"."p' + team.id.to_s + '"'
      puts "[#{Time.now}] (#{i}/#{n}) Adding indexes to partition #{team.id}..."
      execute "CREATE INDEX version_field_p#{team.id} ON #{partition} (version_field_name(event_type, object_after))"
      execute "CREATE INDEX version_annotation_type_p#{team.id} ON #{partition} (version_annotation_type(event_type, object_after))"
      add_index partition, [:item_type, :item_id], name: "item_p#{team.id}"
      add_index partition, :event, name: "version_event_p#{team.id}"
      add_index partition, :whodunnit, name: "version_whodunnit_p#{team.id}"
      add_index partition, :event_type, name: "version_event_type_p#{team.id}"
      add_index partition, :team_id, name: "version_team_id_p#{team.id}"
      add_index partition, [:associated_type, :associated_id], name: "version_associated_p#{team.id}"
    end
    execute 'BEGIN TRANSACTION;'
  end
end
