CREATE OR REPLACE FUNCTION version_annotation_type(event_type TEXT, object_after TEXT)
  RETURNS TEXT AS $name$
  DECLARE
    name TEXT;
  BEGIN
    IF event_type = 'create_dynamic' OR event_type = 'update_dynamic'
    THEN
      SELECT REGEXP_REPLACE(object_after, '^.*annotation_type":"([^"]+).*$', '\1') INTO name;
    ELSE
      SELECT '' INTO name;
    END IF;
    RETURN name;
  END;
  $name$ IMMUTABLE LANGUAGE plpgsql;
