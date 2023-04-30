# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_04_30_222719) do

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
    t.string "url"
    t.text "omniauth_info"
    t.string "uid"
    t.string "provider"
    t.string "token"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_id"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file"
    t.text "attribution"
    t.integer "lock_version", default: 0, null: false
    t.boolean "locked", default: false
    t.text "fragment"
    t.index "task_fieldset((annotation_type)::text, data)", name: "task_fieldset", where: "((annotation_type)::text = 'task'::text)"
    t.index "task_team_task_id((annotation_type)::text, data)", name: "task_team_task_id", where: "((annotation_type)::text = 'task'::text)"
    t.index ["annotated_type", "annotated_id"], name: "index_annotations_on_annotated_type_and_annotated_id"
    t.index ["annotation_type"], name: "index_annotation_type_order"
    t.index ["annotation_type"], name: "index_annotations_on_annotation_type"
  end

  create_table "api_keys", id: :serial, force: :cascade do |t|
    t.string "access_token", default: "", null: false
    t.datetime "expire_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "application"
    t.jsonb "rate_limits", default: {}
  end

  create_table "assignments", id: :serial, force: :cascade do |t|
    t.integer "assigned_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "assigned_type"
    t.integer "assigner_id"
    t.text "message"
    t.index ["assigned_id", "assigned_type", "user_id"], name: "index_assignments_on_assigned_id_and_assigned_type_and_user_id", unique: true
    t.index ["assigned_id", "assigned_type"], name: "index_assignments_on_assigned_id_and_assigned_type"
    t.index ["assigned_id"], name: "index_assignments_on_assigned_id"
    t.index ["assigned_type"], name: "index_assignments_on_assigned_type"
    t.index ["assigner_id"], name: "index_assignments_on_assigner_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "bot_resources", id: :serial, force: :cascade do |t|
    t.string "uuid", default: "", null: false
    t.string "title", default: "", null: false
    t.string "content", default: "", null: false
    t.string "feed_url"
    t.integer "number_of_articles", default: 3
    t.integer "team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["team_id"], name: "index_bot_resources_on_team_id"
    t.index ["uuid"], name: "index_bot_resources_on_uuid", unique: true
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
    t.bigint "project_media_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "context"
    t.index ["project_media_id"], name: "index_claim_descriptions_on_project_media_id", unique: true
    t.index ["user_id"], name: "index_claim_descriptions_on_user_id"
  end

  create_table "clusters", force: :cascade do |t|
    t.integer "project_medias_count", default: 0
    t.integer "project_media_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "first_item_at"
    t.datetime "last_item_at"
    t.index ["project_media_id"], name: "index_clusters_on_project_media_id", unique: true
  end

  create_table "dynamic_annotation_annotation_types", primary_key: "annotation_type", id: :string, force: :cascade do |t|
    t.string "label", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "singleton", default: true
    t.jsonb "json_schema"
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

  create_table "dynamic_annotation_fields", id: :integer, default: -> { "nextval('new_dynamic_annotation_fields_id_seq'::regclass)" }, force: :cascade do |t|
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
    t.index ["field_name"], name: "index_dynamic_annotation_fields_on_field_name"
    t.index ["field_type"], name: "index_dynamic_annotation_fields_on_field_type"
    t.index ["value"], name: "fetch_unique_id", unique: true, where: "(((field_name)::text = 'external_id'::text) AND (value <> ''::text) AND (value <> '\"\"'::text))"
    t.index ["value"], name: "index_status", where: "((field_name)::text = 'verification_status_status'::text)"
    t.index ["value"], name: "smooch_user_unique_id", unique: true, where: "(((field_name)::text = 'smooch_user_id'::text) AND (value <> ''::text) AND (value <> '\"\"'::text))"
    t.index ["value_json"], name: "index_dynamic_annotation_fields_on_value_json", using: :gin
  end

  create_table "fact_checks", force: :cascade do |t|
    t.text "summary"
    t.string "url"
    t.string "title"
    t.bigint "user_id", null: false
    t.bigint "claim_description_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "language", default: "", null: false
    t.index ["claim_description_id"], name: "index_fact_checks_on_claim_description_id", unique: true
    t.index ["language"], name: "index_fact_checks_on_language"
    t.index ["user_id"], name: "index_fact_checks_on_user_id"
  end

  create_table "feed_teams", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "feed_id", null: false
    t.jsonb "filters", default: {}
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "shared", default: false
    t.index ["feed_id"], name: "index_feed_teams_on_feed_id"
    t.index ["team_id", "feed_id"], name: "index_feed_teams_on_team_id_and_feed_id", unique: true
    t.index ["team_id"], name: "index_feed_teams_on_team_id"
  end

  create_table "feeds", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "filters", default: {}
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "published", default: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "quote"
    t.string "type"
    t.string "file"
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
    t.integer "media_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "cached_annotations_count", default: 0
    t.integer "archived", default: 0
    t.integer "targets_count", default: 0, null: false
    t.integer "sources_count", default: 0, null: false
    t.integer "team_id"
    t.boolean "read", default: false, null: false
    t.integer "source_id"
    t.integer "project_id"
    t.integer "last_seen"
    t.integer "cluster_id"
    t.jsonb "channel", default: {"main"=>0}
    t.index ["channel"], name: "index_project_medias_on_channel"
    t.index ["cluster_id"], name: "index_project_medias_on_cluster_id"
    t.index ["last_seen"], name: "index_project_medias_on_last_seen"
    t.index ["media_id"], name: "index_project_medias_on_media_id"
    t.index ["project_id"], name: "index_project_medias_on_project_id"
    t.index ["source_id"], name: "index_project_medias_on_source_id"
    t.index ["team_id", "archived", "sources_count"], name: "index_project_medias_on_team_id_and_archived_and_sources_count"
    t.index ["user_id"], name: "index_project_medias_on_user_id"
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "team_id"
    t.string "title"
    t.boolean "is_default", default: false
    t.text "description"
    t.string "lead_image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "archived", default: 0
    t.text "settings"
    t.string "token"
    t.integer "assignments_count", default: 0
    t.integer "project_group_id"
    t.integer "privacy", default: 0, null: false
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
    t.string "relationship_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.float "weight", default: 0.0
    t.integer "confirmed_by"
    t.datetime "confirmed_at"
    t.string "source_field"
    t.string "target_field"
    t.string "model"
    t.jsonb "details", default: "{}"
    t.float "original_weight", default: 0.0
    t.jsonb "original_details", default: "{}"
    t.string "original_relationship_type"
    t.string "original_model"
    t.integer "original_source_id"
    t.string "original_source_field"
    t.index "LEAST(source_id, target_id), GREATEST(source_id, target_id)", name: "relationships_least_greatest_idx", unique: true
    t.index ["relationship_type"], name: "index_relationships_on_relationship_type"
    t.index ["source_id", "target_id", "relationship_type"], name: "relationship_index", unique: true
    t.index ["target_id"], name: "index_relationships_on_target_id", unique: true
  end

  create_table "requests", force: :cascade do |t|
    t.bigint "feed_id", null: false
    t.string "request_type", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "request_id"
    t.integer "media_id"
    t.integer "medias_count", default: 0, null: false
    t.integer "requests_count", default: 0, null: false
    t.datetime "last_submitted_at"
    t.string "webhook_url"
    t.datetime "last_called_webhook_at"
    t.integer "subscriptions_count", default: 0, null: false
    t.integer "fact_checked_by_count", default: 0, null: false
    t.integer "project_medias_count", default: 0, null: false
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
    t.string "name"
    t.string "slogan"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_id"
    t.string "file"
    t.integer "archived", default: 0
    t.integer "lock_version", default: 0, null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "json_schema"
    t.string "fieldset", default: "", null: false
    t.boolean "show_in_browser_extension", default: true, null: false
    t.text "conditional_info"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "status", default: "member"
    t.text "settings"
    t.string "invitation_email"
    t.string "file"
    t.integer "lock_version", default: 0, null: false
    t.index ["team_id", "user_id"], name: "index_team_users_on_team_id_and_user_id", unique: true
    t.index ["type"], name: "index_team_users_on_type"
    t.index ["user_id", "team_id", "status"], name: "index_team_users_on_user_id_and_team_id_and_status"
    t.index ["user_id", "team_id"], name: "index_team_users_on_user_id_and_team_id"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "logo"
    t.boolean "private", default: true
    t.integer "archived", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "slug"
    t.text "settings"
    t.boolean "inactive", default: false
    t.string "country"
    t.index ["country"], name: "index_teams_on_country"
    t.index ["inactive"], name: "index_teams_on_inactive"
    t.index ["slug"], name: "index_teams_on_slug"
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
    t.index ["external_id"], name: "index_tipline_messages_on_external_id", unique: true
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
    t.index ["tipline_newsletter_id"], name: "index_tipline_newsletter_deliveries_on_tipline_newsletter_id"
  end

  create_table "tipline_newsletters", force: :cascade do |t|
    t.string "introduction", null: false
    t.string "header_type", default: "none", null: false
    t.string "header_file"
    t.string "header_overlay_text"
    t.string "rss_feed_url"
    t.text "first_article"
    t.text "second_article"
    t.text "third_article"
    t.integer "number_of_articles", default: 0, null: false
    t.string "send_every"
    t.string "timezone"
    t.time "time"
    t.datetime "last_sent_at"
    t.string "language", null: false
    t.boolean "enabled", default: false, null: false
    t.bigint "team_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "footer"
    t.integer "last_scheduled_by_id"
    t.datetime "last_scheduled_at"
    t.date "send_on"
    t.string "content_type", default: "static", null: false
    t.index ["team_id", "language"], name: "index_tipline_newsletters_on_team_id_and_language", unique: true
    t.index ["team_id"], name: "index_tipline_newsletters_on_team_id"
  end

  create_table "tipline_subscriptions", id: :serial, force: :cascade do |t|
    t.string "uid"
    t.string "language"
    t.integer "team_id"
    t.string "platform"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image"
    t.integer "current_team_id"
    t.text "settings"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean "is_admin", default: false
    t.text "cached_teams"
    t.string "type"
    t.integer "api_key_id"
    t.integer "source_id"
    t.string "unconfirmed_email"
    t.integer "current_project_id"
    t.boolean "is_active", default: true
    t.datetime "last_accepted_terms_at"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.boolean "completed_signup", default: true
    t.datetime "last_active_at"
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
    t.string "item_type", null: false
    t.string "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.text "object_changes"
    t.datetime "created_at"
    t.text "meta"
    t.string "event_type"
    t.text "object_after"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "team_id"
    t.index ["associated_id"], name: "index_versions_on_associated_id"
    t.index ["event_type"], name: "index_versions_on_event_type"
    t.index ["item_type", "item_id", "whodunnit"], name: "index_versions_on_item_type_and_item_id_and_whodunnit"
    t.index ["team_id"], name: "index_versions_on_team_id"
  end

  add_foreign_key "claim_descriptions", "project_medias"
  add_foreign_key "claim_descriptions", "users"
  add_foreign_key "fact_checks", "claim_descriptions"
  add_foreign_key "fact_checks", "users"
  add_foreign_key "feed_teams", "feeds"
  add_foreign_key "feed_teams", "teams"
  add_foreign_key "project_media_requests", "project_medias"
  add_foreign_key "project_media_requests", "requests"
  add_foreign_key "requests", "feeds"
end
