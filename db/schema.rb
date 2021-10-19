# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_10_14_173355) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "team_id"
    t.text "omniauth_info"
    t.string "uid"
    t.string "provider"
    t.string "token"
    t.string "email"
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
    t.index ["field_type"], name: "index_dynamic_annotation_fields_on_field_type"
    t.index ["value"], name: "index_status", where: "((field_name)::text = 'verification_status_status'::text)"
    t.index ["value_json"], name: "index_dynamic_annotation_fields_on_value_json", using: :gin
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
    t.integer "channel", default: 0
    t.index ["channel"], name: "index_project_medias_on_channel"
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
    t.index ["relationship_type"], name: "index_relationships_on_relationship_type"
    t.index ["source_id", "target_id", "relationship_type"], name: "relationship_index", unique: true
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "status", default: "member"
    t.text "settings"
    t.integer "invited_by_id"
    t.string "invitation_token"
    t.string "raw_invitation_token"
    t.datetime "invitation_accepted_at"
    t.string "invitation_email"
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
    t.index ["inactive"], name: "index_teams_on_inactive"
    t.index ["slug"], name: "index_teams_on_slug"
    t.index ["slug"], name: "unique_team_slugs", unique: true
  end

  create_table "tipline_subscriptions", id: :serial, force: :cascade do |t|
    t.string "uid"
    t.string "language"
    t.integer "team_id"
    t.string "platform"
    t.datetime "created_at", default: "2021-10-19 11:35:58", null: false
    t.datetime "updated_at", default: "2021-10-19 11:35:58", null: false
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
    t.string "invitation_token"
    t.string "raw_invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.datetime "last_accepted_terms_at"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login"
    t.string "otp_backup_codes", array: true
    t.boolean "default", default: false
    t.boolean "completed_signup", default: true
    t.datetime "last_active_at"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email"
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

end
