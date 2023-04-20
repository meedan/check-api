CREATE OR REPLACE FUNCTION task_fieldset(annotation_type TEXT, data TEXT)
  RETURNS TEXT AS $fieldset$
  DECLARE
    fieldset TEXT;
  BEGIN
    IF annotation_type = 'task' AND data LIKE '%fieldset: %'
    THEN
      SELECT REGEXP_REPLACE(data, '^.*fieldset: ([0-9a-z_]+).*$', '\\1') INTO fieldset;
    ELSE
      SELECT NULL INTO fieldset;
    END IF;
    RETURN fieldset;
  END;
  $fieldset$ IMMUTABLE LANGUAGE plpgsql;
