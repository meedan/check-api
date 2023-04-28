CREATE OR REPLACE FUNCTION dynamic_annotation_fields_value(field_name VARCHAR, value TEXT)
  RETURNS TEXT AS $dynamic_field_value$
  DECLARE
    dynamic_field_value TEXT;
  BEGIN
    IF field_name = 'external_id' OR field_name = 'smooch_user_id' OR field_name = 'verification_status_status'
    THEN
      SELECT value INTO dynamic_field_value;
    ELSE
      SELECT NULL INTO dynamic_field_value;
    END IF;
    RETURN dynamic_field_value;
  END;
  $dynamic_field_value$ IMMUTABLE LANGUAGE plpgsql;
