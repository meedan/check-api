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
