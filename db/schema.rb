# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_04_19_100047) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_function :always_fail_on_insert, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.always_fail_on_insert(table_name text)
       RETURNS boolean
       LANGUAGE plpgsql
      AS $function$
                 BEGIN
                   RAISE EXCEPTION 'partitioned table "%" does not support direct inserts, you should be inserting directly into child tables', table_name;
                   RETURN false;
                 END;
                $function$
  SQL
  create_function :version_field_name, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.version_field_name(event_type text, object_after text)
       RETURNS text
       LANGUAGE plpgsql
       IMMUTABLE
      AS $function$
        DECLARE
          name TEXT;
        BEGIN
          IF event_type = 'create_dynamicannotationfield' OR event_type = 'update_dynamicannotationfield'
          THEN
            SELECT REGEXP_REPLACE(object_after, '^.*field_name":"([^"]+).*$', '\1') INTO name;
          ELSE
            SELECT '' INTO name;
          END IF;
          RETURN name;
        END;
        $function$
  SQL
  create_function :version_annotation_type, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.version_annotation_type(event_type text, object_after text)
       RETURNS text
       LANGUAGE plpgsql
       IMMUTABLE
      AS $function$
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
        $function$
  SQL
  create_function :task_team_task_id, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.task_team_task_id(annotation_type text, data text)
       RETURNS integer
       LANGUAGE plpgsql
       IMMUTABLE
      AS $function$
        DECLARE
          team_task_id INTEGER;
        BEGIN
          IF annotation_type = 'task' AND data LIKE '%team_task_id: %'
          THEN
            SELECT REGEXP_REPLACE(data, '^.*team_task_id: ([0-9]+).*$', '\1')::int INTO team_task_id;
          ELSE
            SELECT NULL INTO team_task_id;
          END IF;
          RETURN team_task_id;
        END;
        $function$
  SQL
  create_function :task_fieldset, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.task_fieldset(annotation_type text, data text)
       RETURNS text
       LANGUAGE plpgsql
       IMMUTABLE
      AS $function$
        DECLARE
          fieldset TEXT;
        BEGIN
          IF annotation_type = 'task' AND data LIKE '%fieldset: %'
          THEN
            SELECT REGEXP_REPLACE(data, '^.*fieldset: ([0-9a-z_]+).*$', '\1') INTO fieldset;
          ELSE
            SELECT NULL INTO fieldset;
          END IF;
          RETURN fieldset;
        END;
        $function$
  SQL
  create_function :dynamic_annotation_fields_value, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.dynamic_annotation_fields_value(field_name character varying, value text)
       RETURNS text
       LANGUAGE plpgsql
       IMMUTABLE
      AS $function$
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
        $function$
  SQL
  create_function :validate_relationships, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.validate_relationships()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
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
      $function$
  SQL

  create_table "account_sources", id: :serial, force: :cascade do |t|
    t.integer "account_id"
    t.integer "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "source_id"], name: "index_account_sources_on_account_id_and_source_id", unique: true
    t.index ["source_id"], name: "index_account_sources_on_source_id"
  end

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "team_id"
    t.string "url"
    t.text "omniauth_info"
    t.string "uid"
    t.string "provider"
    t.string "token"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid", "provider", "token", "email"], name: "index_accounts_on_uid_and_provider_and_token_and_email"
    t.index ["url"], name: "index_accounts_on_url", unique: true
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "annotations", id: :serial, force: :cascade do |t|
    t.string "annotation_type", null: false
    t.integer "version_index"
    t.string "annotated_type"
    t.integer "annotated_id"
    t.string "annotator_type"
    t.integer "annotator_id"
    t.text "entities"
    t.text "data"
    t.string "file"
    t.integer "lock_version", default: 0, null: false
    t.boolean "locked", default: false
    t.text "attribution"
    t.text "fragment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index "task_fieldset((annotation_type)::text, data)", name: "task_fieldset", where: "((annotation_type)::text = 'task'::text)"
    t.index "task_team_task_id((annotation_type)::text, data)", name: "task_team_task_id", where: "((annotation_type)::text = 'task'::text)"
    t.index ["annotated_type", "annotated_id"], name: "index_annotations_on_annotated_type_and_annotated_id"
    t.index ["annotation_type"], name: "index_annotation_type_order", opclass: :varchar_pattern_ops
    t.index ["annotation_type"], name: "index_annotations_on_annotation_type"
    t.index ["created_at"], name: "index_annotations_on_created_at"
  end

  create_table "api_keys", id: :serial, force: :cascade do |t|
    t.string "access_token", default: "", null: false
    t.string "title"
    t.integer "user_id"
    t.integer "team_id"
    t.datetime "expire_at"
    t.jsonb "rate_limits", default: {}
    t.string "application"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "description"
  end

  create_table "assignments", id: :serial, force: :cascade do |t|
    t.integer "assigned_id", null: false
    t.integer "user_id", null: false
    t.string "assigned_type"
    t.integer "assigner_id"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_id", "assigned_type", "user_id"], name: "index_assignments_on_assigned_id_and_assigned_type_and_user_id", unique: true
    t.index ["assigned_id", "assigned_type"], name: "index_assignments_on_assigned_id_and_assigned_type"
    t.index ["assigned_id"], name: "index_assignments_on_assigned_id"
    t.index ["assigned_type"], name: "index_assignments_on_assigned_type"
    t.index ["assigner_id"], name: "index_assignments_on_assigner_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "blocked_tipline_users", force: :cascade do |t|
    t.string "uid", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["uid"], name: "index_blocked_tipline_users_on_uid", unique: true
  end

  create_table "bounces", id: :serial, force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_bounces_on_email", unique: true
  end

  create_table "claim_descriptions", force: :cascade do |t|
    t.text "description"
    t.bigint "user_id", null: false
    t.bigint "project_media_id"
    t.text "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "team_id"
    t.bigint "author_id"
    t.index ["author_id"], name: "index_claim_descriptions_on_author_id"
    t.index ["project_media_id"], name: "index_claim_descriptions_on_project_media_id", unique: true
    t.index ["team_id"], name: "index_claim_descriptions_on_team_id"
    t.index ["user_id"], name: "index_claim_descriptions_on_user_id"
  end

  create_table "cluster_project_medias", force: :cascade do |t|
    t.bigint "cluster_id"
    t.bigint "project_media_id"
    t.index ["cluster_id", "project_media_id"], name: "index_cluster_project_medias_on_cluster_id_and_project_media_id", unique: true
    t.index ["cluster_id"], name: "index_cluster_project_medias_on_cluster_id"
    t.index ["project_media_id"], name: "index_cluster_project_medias_on_project_media_id"
  end

  create_table "clusters", force: :cascade do |t|
    t.integer "project_media_id"
    t.datetime "first_item_at"
    t.datetime "last_item_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "feed_id"
    t.integer "team_ids", default: [], null: false, array: true
    t.integer "channels", default: [], null: false, array: true
    t.integer "media_count", default: 0, null: false
    t.integer "requests_count", default: 0, null: false
    t.integer "fact_checks_count", default: 0, null: false
    t.datetime "last_request_date"
    t.datetime "last_fact_check_date"
    t.string "title"
    t.index ["feed_id"], name: "index_clusters_on_feed_id"
    t.index ["project_media_id"], name: "index_clusters_on_project_media_id"
  end

  create_table "dynamic_annotation_annotation_types", primary_key: "annotation_type", id: :string, force: :cascade do |t|
    t.string "label", null: false
    t.text "description"
    t.boolean "singleton", default: true
    t.jsonb "json_schema"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["json_schema"], name: "index_dynamic_annotation_annotation_types_on_json_schema", using: :gin
  end

  create_table "dynamic_annotation_field_instances", primary_key: "name", id: :string, force: :cascade do |t|
    t.string "field_type", null: false
    t.string "annotation_type", null: false
    t.string "label", null: false
    t.text "description"
    t.boolean "optional", default: true
    t.text "settings"
    t.string "default_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dynamic_annotation_field_types", primary_key: "field_type", id: :string, force: :cascade do |t|
    t.string "label", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dynamic_annotation_fields", id: :serial, force: :cascade do |t|
    t.integer "annotation_id", null: false
    t.string "field_name", null: false
    t.string "annotation_type", null: false
    t.string "field_type", null: false
    t.text "value", null: false
    t.jsonb "value_json", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "dynamic_annotation_fields_value(field_name, value)", name: "dynamic_annotation_fields_value", where: "((field_name)::text = ANY ((ARRAY['external_id'::character varying, 'smooch_user_id'::character varying, 'verification_status_status'::character varying])::text[]))"
    t.index ["annotation_id", "field_name"], name: "index_dynamic_annotation_fields_on_annotation_id_and_field_name"
    t.index ["annotation_id"], name: "index_dynamic_annotation_fields_on_annotation_id"
    t.index ["annotation_type"], name: "index_dynamic_annotation_fields_on_annotation_type"
    t.index ["field_name"], name: "index_dynamic_annotation_fields_on_field_name"
    t.index ["field_type"], name: "index_dynamic_annotation_fields_on_field_type"
    t.index ["value"], name: "fetch_unique_id", unique: true, where: "(((field_name)::text = 'external_id'::text) AND (value <> ''::text) AND (value <> '\"\"'::text))"
    t.index ["value"], name: "index_status", where: "((field_name)::text = 'verification_status_status'::text)"
    t.index ["value"], name: "smooch_user_unique_id", unique: true, where: "(((field_name)::text = 'smooch_user_id'::text) AND (value <> ''::text) AND (value <> '\"\"'::text))"
    t.index ["value"], name: "translation_request_id", unique: true, where: "((field_name)::text = 'translation_request_id'::text)"
    t.index ["value_json"], name: "index_dynamic_annotation_fields_on_value_json", using: :gin
  end

  create_table "explainer_items", force: :cascade do |t|
    t.bigint "explainer_id"
    t.bigint "project_media_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["explainer_id", "project_media_id"], name: "index_explainer_items_on_explainer_id_and_project_media_id", unique: true
    t.index ["explainer_id"], name: "index_explainer_items_on_explainer_id"
    t.index ["project_media_id"], name: "index_explainer_items_on_project_media_id"
  end

  create_table "explainers", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "url"
    t.string "language"
    t.bigint "user_id", null: false
    t.bigint "team_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "tags", default: [], array: true
    t.boolean "trashed", default: false
    t.bigint "author_id"
    t.integer "channel", null: false
    t.index "date_trunc('day'::text, created_at)", name: "explainer_created_at_day"
    t.index ["author_id"], name: "index_explainers_on_author_id"
    t.index ["channel"], name: "index_explainers_on_channel"
    t.index ["created_at"], name: "index_explainers_on_created_at"
    t.index ["tags"], name: "index_explainers_on_tags", using: :gin
    t.index ["team_id"], name: "index_explainers_on_team_id"
    t.index ["user_id"], name: "index_explainers_on_user_id"
  end

  create_table "fact_checks", force: :cascade do |t|
    t.text "summary"
    t.string "url"
    t.string "title"
    t.bigint "user_id", null: false
    t.bigint "claim_description_id", null: false
    t.string "language", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "signature"
    t.string "tags", default: [], array: true
    t.integer "publisher_id"
    t.integer "report_status", default: 0
    t.string "rating"
    t.boolean "imported", default: false
    t.boolean "trashed", default: false
    t.bigint "author_id"
    t.integer "channel", null: false
    t.index "date_trunc('day'::text, created_at)", name: "fact_check_created_at_day"
    t.index ["author_id"], name: "index_fact_checks_on_author_id"
    t.index ["channel"], name: "index_fact_checks_on_channel"
    t.index ["claim_description_id"], name: "index_fact_checks_on_claim_description_id", unique: true
    t.index ["created_at"], name: "index_fact_checks_on_created_at"
    t.index ["imported"], name: "index_fact_checks_on_imported"
    t.index ["language"], name: "index_fact_checks_on_language"
    t.index ["publisher_id"], name: "index_fact_checks_on_publisher_id"
    t.index ["rating"], name: "index_fact_checks_on_rating"
    t.index ["report_status"], name: "index_fact_checks_on_report_status"
    t.index ["signature"], name: "index_fact_checks_on_signature", unique: true
    t.index ["tags"], name: "index_fact_checks_on_tags", using: :gin
    t.index ["user_id"], name: "index_fact_checks_on_user_id"
  end

  create_table "feed_invitations", force: :cascade do |t|
    t.string "email", null: false
    t.integer "state", default: 0, null: false
    t.bigint "feed_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email", "feed_id"], name: "index_feed_invitations_on_email_and_feed_id", unique: true
    t.index ["feed_id"], name: "index_feed_invitations_on_feed_id"
    t.index ["user_id"], name: "index_feed_invitations_on_user_id"
  end

  create_table "feed_teams", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "feed_id", null: false
    t.jsonb "settings", default: {}
    t.boolean "shared", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "saved_search_id"
    t.index ["feed_id"], name: "index_feed_teams_on_feed_id"
    t.index ["saved_search_id"], name: "index_feed_teams_on_saved_search_id"
    t.index ["team_id", "feed_id"], name: "index_feed_teams_on_team_id_and_feed_id", unique: true
    t.index ["team_id"], name: "index_feed_teams_on_team_id"
  end

  create_table "feeds", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "settings", default: {}
    t.boolean "published", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "saved_search_id"
    t.bigint "user_id"
    t.bigint "team_id"
    t.text "description"
    t.string "tags", default: [], array: true
    t.integer "licenses", default: [], array: true
    t.boolean "discoverable", default: false
    t.integer "data_points", default: [], array: true
    t.string "uuid", default: "", null: false
    t.datetime "last_clusterized_at"
    t.index ["saved_search_id"], name: "index_feeds_on_saved_search_id"
    t.index ["team_id"], name: "index_feeds_on_team_id"
    t.index ["user_id"], name: "index_feeds_on_user_id"
    t.index ["uuid"], name: "index_feeds_on_uuid"
  end

  create_table "login_activities", id: :serial, force: :cascade do |t|
    t.string "scope"
    t.string "strategy"
    t.string "identity"
    t.boolean "success"
    t.string "failure_reason"
    t.string "user_type"
    t.integer "user_id"
    t.string "context"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.datetime "created_at"
    t.index ["identity"], name: "index_login_activities_on_identity"
    t.index ["ip"], name: "index_login_activities_on_ip"
  end

  create_table "medias", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_id"
    t.string "url"
    t.string "file"
    t.string "quote"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "uuid", default: 0, null: false
    t.text "original_claim"
    t.string "original_claim_hash"
    t.index ["original_claim_hash"], name: "index_medias_on_original_claim_hash", unique: true
    t.index ["url"], name: "index_medias_on_url", unique: true
  end

  create_table "monthly_team_statistics", force: :cascade do |t|
    t.integer "conversations"
    t.integer "average_messages_per_day"
    t.integer "unique_users"
    t.integer "returning_users"
    t.integer "valid_new_requests"
    t.integer "published_native_reports"
    t.integer "published_imported_reports"
    t.integer "requests_answered_with_report"
    t.integer "reports_sent_to_users"
    t.integer "unique_users_who_received_report"
    t.integer "median_response_time"
    t.integer "unique_newsletters_sent"
    t.integer "new_newsletter_subscriptions"
    t.integer "newsletter_cancellations"
    t.integer "current_subscribers"
    t.datetime "start_date"
    t.datetime "end_date"
    t.string "platform"
    t.string "language"
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "conversations_24hr"
    t.integer "newsletters_delivered"
    t.integer "whatsapp_conversations"
    t.integer "published_reports"
    t.integer "positive_searches"
    t.integer "negative_searches"
    t.integer "newsletters_sent"
    t.integer "whatsapp_conversations_user"
    t.integer "whatsapp_conversations_business"
    t.integer "positive_feedback"
    t.integer "negative_feedback"
    t.index ["team_id", "platform", "language", "start_date"], name: "index_monthly_stats_team_platform_language_start", unique: true
    t.index ["team_id"], name: "index_monthly_team_statistics_on_team_id"
  end

  create_table "pghero_query_stats", id: :serial, force: :cascade do |t|
    t.text "database"
    t.text "user"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.bigint "calls"
    t.datetime "captured_at"
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "project_groups", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.integer "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_project_groups_on_team_id"
  end

  create_table "project_media_requests", force: :cascade do |t|
    t.bigint "project_media_id", null: false
    t.bigint "request_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_media_id"], name: "index_project_media_requests_on_project_media_id"
    t.index ["request_id", "project_media_id"], name: "index_project_media_requests_on_request_id_and_project_media_id", unique: true
    t.index ["request_id"], name: "index_project_media_requests_on_request_id"
  end

  create_table "project_media_users", id: :serial, force: :cascade do |t|
    t.integer "project_media_id"
    t.integer "user_id"
    t.boolean "read", default: false, null: false
    t.index ["project_media_id", "user_id"], name: "index_project_media_users_on_project_media_id_and_user_id", unique: true
    t.index ["project_media_id"], name: "index_project_media_users_on_project_media_id"
    t.index ["user_id"], name: "index_project_media_users_on_user_id"
  end

  create_table "project_medias", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "media_id"
    t.integer "user_id"
    t.integer "source_id"
    t.integer "team_id"
    t.jsonb "channel", default: {"main"=>0}
    t.boolean "read", default: false, null: false
    t.integer "sources_count", default: 0, null: false
    t.integer "archived", default: 0
    t.integer "last_seen"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "unmatched", default: 0
    t.string "custom_title"
    t.string "title_field"
    t.integer "imported_from_feed_id"
    t.integer "imported_from_project_media_id"
    t.index ["channel"], name: "index_project_medias_on_channel"
    t.index ["last_seen"], name: "index_project_medias_on_last_seen"
    t.index ["media_id"], name: "index_project_medias_on_media_id"
    t.index ["project_id"], name: "index_project_medias_on_project_id"
    t.index ["source_id"], name: "index_project_medias_on_source_id"
    t.index ["team_id", "archived", "sources_count"], name: "index_project_medias_on_team_id_and_archived_and_sources_count"
    t.index ["unmatched"], name: "index_project_medias_on_unmatched"
    t.index ["user_id"], name: "index_project_medias_on_user_id"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "team_id"
    t.integer "project_group_id"
    t.string "title"
    t.boolean "is_default", default: false
    t.text "description"
    t.string "lead_image"
    t.string "token"
    t.integer "assignments_count", default: 0
    t.integer "privacy", default: 0, null: false
    t.integer "archived", default: 0
    t.text "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_projects_on_id"
    t.index ["is_default"], name: "index_projects_on_is_default"
    t.index ["privacy"], name: "index_projects_on_privacy"
    t.index ["project_group_id"], name: "index_projects_on_project_group_id"
    t.index ["team_id"], name: "index_projects_on_team_id"
    t.index ["token"], name: "index_projects_on_token", unique: true
  end

  create_table "relationships", id: :serial, force: :cascade do |t|
    t.integer "source_id", null: false
    t.integer "target_id", null: false
    t.integer "user_id"
    t.string "relationship_type", null: false
    t.float "original_weight", default: 0.0
    t.float "float", default: 0.0
    t.jsonb "original_details", default: "{}"
    t.string "original_relationship_type"
    t.string "original_model"
    t.integer "original_source_id"
    t.string "original_source_field"
    t.integer "confirmed_by"
    t.datetime "confirmed_at"
    t.float "weight", default: 0.0
    t.string "source_field"
    t.string "target_field"
    t.string "model"
    t.jsonb "details", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "LEAST(source_id, target_id), GREATEST(source_id, target_id)", name: "relationships_least_greatest_idx", unique: true
    t.index ["relationship_type"], name: "index_relationships_on_relationship_type"
    t.index ["source_id", "relationship_type"], name: "index_relationships_on_source_id_and_relationship_type"
    t.index ["source_id", "target_id", "relationship_type"], name: "relationship_index", unique: true
    t.index ["source_id"], name: "index_relationships_on_source_id"
    t.index ["target_id", "relationship_type"], name: "index_relationships_on_target_id_and_relationship_type"
    t.index ["target_id"], name: "index_relationships_on_target_id", unique: true
    t.check_constraint "source_id <> target_id", name: "source_target_must_be_different"
  end

  create_table "relevant_results_items", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "team_id"
    t.string "relevant_results_render_id"
    t.string "user_action"
    t.integer "query_media_parent_id"
    t.integer "query_media_ids", default: [], array: true
    t.jsonb "similarity_settings", default: {}
    t.integer "matched_media_id"
    t.integer "selected_count"
    t.integer "display_rank"
    t.string "article_type", null: false
    t.bigint "article_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["article_type", "article_id"], name: "index_relevant_results_items_on_article"
    t.index ["article_type", "article_id"], name: "index_relevant_results_items_on_article_type_and_article_id"
    t.index ["team_id"], name: "index_relevant_results_items_on_team_id"
    t.index ["user_id"], name: "index_relevant_results_items_on_user_id"
  end

  create_table "requests", force: :cascade do |t|
    t.bigint "feed_id", null: false
    t.string "request_type", null: false
    t.text "content", null: false
    t.integer "request_id"
    t.integer "media_id"
    t.integer "fact_checked_by_count", default: 0, null: false
    t.integer "project_medias_count", default: 0, null: false
    t.integer "medias_count", default: 0, null: false
    t.integer "requests_count", default: 0, null: false
    t.datetime "last_submitted_at"
    t.string "webhook_url"
    t.datetime "last_called_webhook_at"
    t.integer "subscriptions_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feed_id"], name: "index_requests_on_feed_id"
    t.index ["media_id"], name: "index_requests_on_media_id"
    t.index ["request_id"], name: "index_requests_on_request_id"
  end

  create_table "saved_searches", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.integer "team_id", null: false
    t.json "filters"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "list_type", default: 0, null: false
    t.index ["list_type"], name: "index_saved_searches_on_list_type"
    t.index ["team_id"], name: "index_saved_searches_on_team_id"
  end

  create_table "shortened_urls", id: :serial, force: :cascade do |t|
    t.integer "owner_id"
    t.string "owner_type", limit: 20
    t.text "url", null: false
    t.string "unique_key", limit: 10, null: false
    t.string "category"
    t.integer "use_count", default: 0, null: false
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["category"], name: "index_shortened_urls_on_category"
    t.index ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type"
    t.index ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true
    t.index ["url"], name: "index_shortened_urls_on_url"
  end

  create_table "sources", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "team_id"
    t.string "name"
    t.string "slogan"
    t.string "avatar"
    t.integer "archived", default: 0
    t.string "file"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tag_texts", id: :serial, force: :cascade do |t|
    t.string "text", null: false
    t.integer "team_id", null: false
    t.integer "tags_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["text", "team_id"], name: "index_tag_texts_on_text_and_team_id", unique: true
  end

  create_table "team_tasks", id: :serial, force: :cascade do |t|
    t.string "label", null: false
    t.string "task_type", null: false
    t.text "description"
    t.text "options"
    t.text "project_ids"
    t.text "mapping"
    t.boolean "required", default: false
    t.integer "team_id", null: false
    t.integer "order", default: 0
    t.string "associated_type", default: "ProjectMedia", null: false
    t.string "fieldset", default: "", null: false
    t.boolean "show_in_browser_extension", default: true, null: false
    t.string "json_schema"
    t.text "conditional_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "fieldset", "associated_type"], name: "index_team_tasks_on_team_id_and_fieldset_and_associated_type"
  end

  create_table "team_users", id: :serial, force: :cascade do |t|
    t.integer "team_id"
    t.integer "user_id"
    t.string "type"
    t.integer "invited_by_id"
    t.string "invitation_token"
    t.string "raw_invitation_token"
    t.datetime "invitation_accepted_at"
    t.string "file"
    t.text "settings"
    t.string "role"
    t.string "status", default: "member"
    t.string "invitation_email"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "user_id"], name: "index_team_users_on_team_id_and_user_id", unique: true
    t.index ["type"], name: "index_team_users_on_type"
    t.index ["user_id", "team_id", "status"], name: "index_team_users_on_user_id_and_team_id_and_status"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "logo"
    t.boolean "private", default: true, null: false
    t.integer "archived", default: 0
    t.string "country"
    t.text "description"
    t.string "slug"
    t.boolean "inactive", default: false
    t.text "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country"], name: "index_teams_on_country"
    t.index ["inactive"], name: "index_teams_on_inactive"
    t.index ["slug"], name: "unique_team_slugs", unique: true
  end

  create_table "tipline_messages", force: :cascade do |t|
    t.string "event"
    t.integer "direction", default: 0
    t.string "language"
    t.string "platform"
    t.datetime "sent_at"
    t.string "uid"
    t.string "external_id"
    t.jsonb "payload", default: {}
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.index "date_trunc('day'::text, created_at)", name: "tipline_message_created_at_day"
    t.index "date_trunc('month'::text, created_at)", name: "tipline_message_created_at_month"
    t.index "date_trunc('quarter'::text, created_at)", name: "tipline_message_created_at_quarter"
    t.index "date_trunc('week'::text, created_at)", name: "tipline_message_created_at_week"
    t.index "date_trunc('year'::text, created_at)", name: "tipline_message_created_at_year"
    t.index ["created_at"], name: "index_tipline_messages_on_created_at"
    t.index ["external_id", "state"], name: "index_tipline_messages_on_external_id_and_state", unique: true
    t.index ["team_id"], name: "index_tipline_messages_on_team_id"
    t.index ["uid"], name: "index_tipline_messages_on_uid"
  end

  create_table "tipline_newsletter_deliveries", force: :cascade do |t|
    t.integer "recipients_count", default: 0, null: false
    t.text "content", null: false
    t.datetime "started_sending_at", null: false
    t.datetime "finished_sending_at", null: false
    t.bigint "tipline_newsletter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tipline_newsletter_deliveries_on_created_at"
    t.index ["tipline_newsletter_id"], name: "index_tipline_newsletter_deliveries_on_tipline_newsletter_id"
  end

  create_table "tipline_newsletters", force: :cascade do |t|
    t.string "header_type", default: "none", null: false
    t.string "header_file"
    t.string "header_overlay_text"
    t.string "header_media_url"
    t.string "introduction", null: false
    t.string "content_type", default: "static", null: false
    t.string "rss_feed_url"
    t.text "first_article"
    t.text "second_article"
    t.text "third_article"
    t.integer "number_of_articles", default: 0, null: false
    t.string "footer"
    t.string "send_every"
    t.date "send_on"
    t.string "timezone"
    t.time "time"
    t.datetime "last_sent_at"
    t.datetime "last_scheduled_at"
    t.integer "last_scheduled_by_id"
    t.string "last_delivery_error"
    t.string "language", null: false
    t.boolean "enabled", default: false, null: false
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "language"], name: "index_tipline_newsletters_on_team_id_and_language", unique: true
    t.index ["team_id"], name: "index_tipline_newsletters_on_team_id"
  end

  create_table "tipline_requests", force: :cascade do |t|
    t.string "language", null: false
    t.string "tipline_user_uid"
    t.string "platform", null: false
    t.string "smooch_request_type", null: false
    t.string "smooch_resource_id"
    t.string "smooch_message_id", default: ""
    t.string "smooch_conversation_id"
    t.jsonb "smooch_data", default: {}, null: false
    t.string "associated_type", null: false
    t.bigint "associated_id", null: false
    t.bigint "team_id", null: false
    t.bigint "user_id"
    t.integer "smooch_report_received_at", default: 0
    t.integer "smooch_report_update_received_at", default: 0
    t.integer "smooch_report_correction_sent_at", default: 0
    t.integer "smooch_report_sent_at", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "first_manual_response_at", default: 0, null: false
    t.integer "last_manual_response_at", default: 0, null: false
    t.index "date_trunc('day'::text, created_at)", name: "tipline_request_created_at_day"
    t.index "date_trunc('month'::text, created_at)", name: "tipline_request_created_at_month"
    t.index "date_trunc('quarter'::text, created_at)", name: "tipline_request_created_at_quarter"
    t.index "date_trunc('week'::text, created_at)", name: "tipline_request_created_at_week"
    t.index "date_trunc('year'::text, created_at)", name: "tipline_request_created_at_year"
    t.index ["associated_type", "associated_id"], name: "index_tipline_requests_on_associated"
    t.index ["associated_type", "associated_id"], name: "index_tipline_requests_on_associated_type_and_associated_id"
    t.index ["created_at"], name: "index_tipline_requests_on_created_at"
    t.index ["language"], name: "index_tipline_requests_on_language"
    t.index ["platform"], name: "index_tipline_requests_on_platform"
    t.index ["smooch_message_id"], name: "index_tipline_requests_on_smooch_message_id", unique: true, where: "((smooch_message_id IS NOT NULL) AND ((smooch_message_id)::text <> ''::text))"
    t.index ["team_id"], name: "index_tipline_requests_on_team_id"
    t.index ["tipline_user_uid"], name: "index_tipline_requests_on_tipline_user_uid"
    t.index ["user_id"], name: "index_tipline_requests_on_user_id"
  end

  create_table "tipline_resources", id: :serial, force: :cascade do |t|
    t.string "uuid", default: "", null: false
    t.string "title", default: "", null: false
    t.string "content", default: "", null: false
    t.string "rss_feed_url"
    t.integer "number_of_articles", default: 3
    t.integer "team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "language"
    t.string "content_type"
    t.string "header_type", default: "link_preview", null: false
    t.string "header_file"
    t.string "header_overlay_text"
    t.string "header_media_url"
    t.string "keywords", default: [], array: true
    t.index ["team_id"], name: "index_tipline_resources_on_team_id"
    t.index ["uuid"], name: "index_tipline_resources_on_uuid", unique: true
  end

  create_table "tipline_subscriptions", id: :serial, force: :cascade do |t|
    t.string "uid"
    t.string "language"
    t.integer "team_id"
    t.string "platform"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["created_at"], name: "index_tipline_subscriptions_on_created_at"
    t.index ["language", "team_id"], name: "index_tipline_subscriptions_on_language_and_team_id"
    t.index ["language"], name: "index_tipline_subscriptions_on_language"
    t.index ["platform"], name: "index_tipline_subscriptions_on_platform"
    t.index ["team_id"], name: "index_tipline_subscriptions_on_team_id"
    t.index ["uid", "language", "team_id"], name: "index_tipline_subscriptions_on_uid_and_language_and_team_id", unique: true
    t.index ["uid"], name: "index_tipline_subscriptions_on_uid"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "login", default: "", null: false
    t.string "token", default: "", null: false
    t.boolean "default", default: false
    t.string "email"
    t.string "encrypted_password", default: ""
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "invitation_token"
    t.string "raw_invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.datetime "last_accepted_terms_at"
    t.string "image"
    t.string "type"
    t.integer "source_id"
    t.boolean "is_active", default: true
    t.boolean "is_admin", default: false
    t.integer "current_project_id"
    t.integer "integer"
    t.text "settings"
    t.datetime "last_active_at"
    t.text "cached_teams"
    t.integer "current_team_id"
    t.boolean "completed_signup", default: true
    t.integer "api_key_id"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "last_received_terms_email_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true, where: "((email IS NOT NULL) AND ((email)::text <> ''::text))"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["login"], name: "index_users_on_login"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["source_id"], name: "index_users_on_source_id"
    t.index ["token"], name: "index_users_on_token", unique: true
    t.index ["type"], name: "index_users_on_type"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.string "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.text "object_changes"
    t.datetime "created_at"
    t.text "meta"
    t.integer "associated_id"
    t.string "associated_type"
    t.string "event_type"
    t.integer "team_id"
    t.text "object_after"
    t.index ["associated_id"], name: "index_versions_on_associated_id"
    t.index ["event_type"], name: "index_versions_on_event_type"
    t.index ["item_type", "item_id", "whodunnit"], name: "index_versions_on_item_type_and_item_id_and_whodunnit"
    t.index ["team_id"], name: "index_versions_on_team_id"
  end

  add_foreign_key "claim_descriptions", "project_medias"
  add_foreign_key "claim_descriptions", "users"
  add_foreign_key "explainer_items", "explainers"
  add_foreign_key "explainer_items", "project_medias"
  add_foreign_key "explainers", "teams"
  add_foreign_key "explainers", "users"
  add_foreign_key "fact_checks", "claim_descriptions"
  add_foreign_key "fact_checks", "users"
  add_foreign_key "feed_invitations", "feeds"
  add_foreign_key "feed_invitations", "users"
  add_foreign_key "feed_teams", "feeds"
  add_foreign_key "feed_teams", "teams"
  add_foreign_key "project_media_requests", "project_medias"
  add_foreign_key "project_media_requests", "requests"
  add_foreign_key "requests", "feeds"

  create_trigger :enforce_relationships, sql_definition: <<-SQL
      CREATE TRIGGER enforce_relationships BEFORE INSERT ON public.relationships FOR EACH ROW PROCEDURE FUNCTION validate_relationships()
  SQL
end
