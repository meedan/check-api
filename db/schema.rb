# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20200506223124) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "account_sources", force: :cascade do |t|
    t.integer  "account_id"
    t.integer  "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "account_sources", ["account_id", "source_id"], name: "index_account_sources_on_account_id_and_source_id", unique: true, using: :btree
  add_index "account_sources", ["source_id"], name: "index_account_sources_on_source_id", using: :btree

  create_table "accounts", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "url"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "team_id"
    t.text     "omniauth_info"
    t.string   "uid"
    t.string   "provider"
    t.string   "token"
    t.string   "email"
  end

  add_index "accounts", ["uid", "provider", "token", "email"], name: "index_accounts_on_uid_and_provider_and_token_and_email", using: :btree
  add_index "accounts", ["url"], name: "index_accounts_on_url", unique: true, using: :btree

  create_table "annotations", force: :cascade do |t|
    t.string   "annotation_type",                 null: false
    t.integer  "version_index"
    t.string   "annotated_type"
    t.integer  "annotated_id"
    t.string   "annotator_type"
    t.integer  "annotator_id"
    t.text     "entities"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file"
    t.text     "attribution"
    t.integer  "lock_version",    default: 0,     null: false
    t.boolean  "locked",          default: false
    t.text     "fragment"
  end

  add_index "annotations", ["annotated_type", "annotated_id"], name: "index_annotations_on_annotated_type_and_annotated_id", using: :btree
  add_index "annotations", ["annotation_type"], name: "index_annotation_type_order", using: :btree
  add_index "annotations", ["annotation_type"], name: "index_annotations_on_annotation_type", using: :btree

  create_table "api_keys", force: :cascade do |t|
    t.string   "access_token", default: "", null: false
    t.datetime "expire_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "application"
  end

  create_table "assignments", force: :cascade do |t|
    t.integer  "assigned_id",   null: false
    t.integer  "user_id",       null: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "assigned_type"
    t.integer  "assigner_id"
  end

  add_index "assignments", ["assigned_id", "assigned_type", "user_id"], name: "index_assignments_on_assigned_id_and_assigned_type_and_user_id", unique: true, using: :btree
  add_index "assignments", ["assigned_id", "assigned_type"], name: "index_assignments_on_assigned_id_and_assigned_type", using: :btree
  add_index "assignments", ["assigned_id"], name: "index_assignments_on_assigned_id", using: :btree
  add_index "assignments", ["assigned_type"], name: "index_assignments_on_assigned_type", using: :btree
  add_index "assignments", ["assigner_id"], name: "index_assignments_on_assigner_id", using: :btree
  add_index "assignments", ["user_id"], name: "index_assignments_on_user_id", using: :btree

  create_table "bounces", force: :cascade do |t|
    t.string   "email",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "bounces", ["email"], name: "index_bounces_on_email", unique: true, using: :btree

  create_table "claim_sources", force: :cascade do |t|
    t.integer  "media_id"
    t.integer  "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "claim_sources", ["media_id", "source_id"], name: "index_claim_sources_on_media_id_and_source_id", unique: true, using: :btree

  create_table "contacts", force: :cascade do |t|
    t.integer  "team_id"
    t.string   "location"
    t.string   "phone"
    t.string   "web"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dynamic_annotation_annotation_types", primary_key: "annotation_type", force: :cascade do |t|
    t.string   "label",                      null: false
    t.text     "description"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.boolean  "singleton",   default: true
    t.jsonb    "json_schema"
  end

  add_index "dynamic_annotation_annotation_types", ["json_schema"], name: "index_dynamic_annotation_annotation_types_on_json_schema", using: :gin

  create_table "dynamic_annotation_field_instances", primary_key: "name", force: :cascade do |t|
    t.string   "field_type",                     null: false
    t.string   "annotation_type",                null: false
    t.string   "label",                          null: false
    t.text     "description"
    t.boolean  "optional",        default: true
    t.text     "settings"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "default_value"
  end

  create_table "dynamic_annotation_field_types", primary_key: "field_type", force: :cascade do |t|
    t.string   "label",       null: false
    t.text     "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "dynamic_annotation_fields", force: :cascade do |t|
    t.integer  "annotation_id",                null: false
    t.string   "field_name",                   null: false
    t.string   "annotation_type",              null: false
    t.string   "field_type",                   null: false
    t.text     "value",                        null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.jsonb    "value_json",      default: {}
  end

  add_index "dynamic_annotation_fields", ["annotation_id"], name: "index_dynamic_annotation_fields_on_annotation_id", using: :btree
  add_index "dynamic_annotation_fields", ["field_type"], name: "index_dynamic_annotation_fields_on_field_type", using: :btree
  add_index "dynamic_annotation_fields", ["value"], name: "translation_request_id", unique: true, where: "((field_name)::text = 'translation_request_id'::text)", using: :btree
  add_index "dynamic_annotation_fields", ["value_json"], name: "index_dynamic_annotation_fields_on_value_json", using: :gin

  create_table "login_activities", force: :cascade do |t|
    t.string   "scope"
    t.string   "strategy"
    t.string   "identity"
    t.boolean  "success"
    t.string   "failure_reason"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "context"
    t.string   "ip"
    t.text     "user_agent"
    t.text     "referrer"
    t.datetime "created_at"
  end

  add_index "login_activities", ["identity"], name: "index_login_activities_on_identity", using: :btree
  add_index "login_activities", ["ip"], name: "index_login_activities_on_ip", using: :btree

  create_table "medias", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.string   "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "quote"
    t.string   "type"
    t.string   "file"
  end

  add_index "medias", ["id"], name: "index_medias_on_id", using: :btree
  add_index "medias", ["url"], name: "index_medias_on_url", unique: true, using: :btree

  create_table "pghero_query_stats", force: :cascade do |t|
    t.text     "database"
    t.text     "user"
    t.text     "query"
    t.integer  "query_hash",  limit: 8
    t.float    "total_time"
    t.integer  "calls",       limit: 8
    t.datetime "captured_at"
  end

  add_index "pghero_query_stats", ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at", using: :btree

  create_table "project_media_projects", force: :cascade do |t|
    t.integer "project_media_id"
    t.integer "project_id"
  end

  add_index "project_media_projects", ["project_id"], name: "index_project_media_projects_on_project_id", using: :btree
  add_index "project_media_projects", ["project_media_id", "project_id"], name: "index_project_media_projects_on_project_media_id_and_project_id", unique: true, using: :btree
  add_index "project_media_projects", ["project_media_id"], name: "index_project_media_projects_on_project_media_id", using: :btree

  create_table "project_medias", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "media_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "user_id"
    t.integer  "cached_annotations_count", default: 0
    t.boolean  "archived",                 default: false
    t.integer  "targets_count",            default: 0,     null: false
    t.integer  "sources_count",            default: 0,     null: false
    t.boolean  "inactive",                 default: false
    t.integer  "team_id"
  end

  add_index "project_medias", ["id"], name: "index_project_medias_on_id", using: :btree
  add_index "project_medias", ["inactive"], name: "index_project_medias_on_inactive", using: :btree
  add_index "project_medias", ["media_id"], name: "index_project_medias_on_media_id", using: :btree
  add_index "project_medias", ["project_id", "media_id"], name: "index_project_medias_on_project_id_and_media_id", unique: true, using: :btree
  add_index "project_medias", ["team_id"], name: "index_project_medias_on_team_id", using: :btree

  create_table "project_sources", force: :cascade do |t|
    t.integer  "project_id"
    t.integer  "source_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "user_id"
    t.integer  "cached_annotations_count", default: 0
  end

  add_index "project_sources", ["project_id", "source_id"], name: "index_project_sources_on_project_id_and_source_id", unique: true, using: :btree

  create_table "projects", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "team_id"
    t.string   "title"
    t.text     "description"
    t.string   "lead_image"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "archived",          default: false
    t.text     "settings"
    t.string   "token"
    t.integer  "assignments_count", default: 0
  end

  add_index "projects", ["id"], name: "index_projects_on_id", using: :btree
  add_index "projects", ["team_id"], name: "index_projects_on_team_id", using: :btree
  add_index "projects", ["token"], name: "index_projects_on_token", unique: true, using: :btree

  create_table "relationships", force: :cascade do |t|
    t.integer  "source_id",         null: false
    t.integer  "target_id",         null: false
    t.string   "relationship_type", null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "user_id"
  end

  add_index "relationships", ["source_id", "target_id", "relationship_type"], name: "relationship_index", unique: true, using: :btree

  create_table "shortened_urls", force: :cascade do |t|
    t.integer  "owner_id"
    t.string   "owner_type", limit: 20
    t.text     "url",                               null: false
    t.string   "unique_key", limit: 10,             null: false
    t.string   "category"
    t.integer  "use_count",             default: 0, null: false
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shortened_urls", ["category"], name: "index_shortened_urls_on_category", using: :btree
  add_index "shortened_urls", ["owner_id", "owner_type"], name: "index_shortened_urls_on_owner_id_and_owner_type", using: :btree
  add_index "shortened_urls", ["unique_key"], name: "index_shortened_urls_on_unique_key", unique: true, using: :btree
  add_index "shortened_urls", ["url"], name: "index_shortened_urls_on_url", using: :btree

  create_table "sources", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "slogan"
    t.string   "avatar"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "team_id"
    t.string   "file"
    t.boolean  "archived",     default: false
    t.integer  "lock_version", default: 0,     null: false
  end

  create_table "tag_texts", force: :cascade do |t|
    t.string   "text",                       null: false
    t.integer  "team_id",                    null: false
    t.integer  "tags_count", default: 0
    t.boolean  "teamwide",   default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "tag_texts", ["text", "team_id"], name: "index_tag_texts_on_text_and_team_id", unique: true, using: :btree

  create_table "team_tasks", force: :cascade do |t|
    t.string   "label",                       null: false
    t.string   "task_type",                   null: false
    t.text     "description"
    t.text     "options"
    t.text     "project_ids"
    t.text     "mapping"
    t.boolean  "required",    default: false
    t.integer  "team_id",                     null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "json_schema"
  end

  create_table "team_users", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "user_id"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "role"
    t.string   "status",                 default: "member"
    t.integer  "invited_by_id"
    t.string   "invitation_token"
    t.string   "raw_invitation_token"
    t.datetime "invitation_accepted_at"
    t.text     "settings"
    t.string   "type"
    t.string   "invitation_email"
  end

  add_index "team_users", ["id"], name: "index_team_users_on_id", using: :btree
  add_index "team_users", ["team_id", "user_id"], name: "index_team_users_on_team_id_and_user_id", unique: true, using: :btree
  add_index "team_users", ["type"], name: "index_team_users_on_type", using: :btree
  add_index "team_users", ["user_id", "team_id"], name: "index_team_users_on_user_id_and_team_id", using: :btree

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.string   "logo"
    t.boolean  "private",     default: true
    t.boolean  "archived",    default: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "description"
    t.string   "slug"
    t.text     "settings"
    t.boolean  "inactive",    default: false
  end

  add_index "teams", ["id"], name: "index_teams_on_id", using: :btree
  add_index "teams", ["inactive"], name: "index_teams_on_inactive", using: :btree
  add_index "teams", ["slug"], name: "index_teams_on_slug", using: :btree
  add_index "teams", ["slug"], name: "unique_team_slugs", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "name",                      default: "",    null: false
    t.string   "login",                     default: "",    null: false
    t.string   "token",                     default: "",    null: false
    t.string   "email"
    t.string   "encrypted_password",        default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",             default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "image"
    t.integer  "current_team_id"
    t.text     "settings"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.boolean  "is_admin",                  default: false
    t.text     "cached_teams"
    t.string   "type"
    t.integer  "api_key_id"
    t.integer  "source_id"
    t.string   "unconfirmed_email"
    t.integer  "current_project_id"
    t.boolean  "is_active",                 default: true
    t.datetime "last_accepted_terms_at"
    t.string   "invitation_token"
    t.string   "raw_invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.string   "encrypted_otp_secret"
    t.string   "encrypted_otp_secret_iv"
    t.string   "encrypted_otp_secret_salt"
    t.integer  "consumed_timestep"
    t.boolean  "otp_required_for_login"
    t.string   "otp_backup_codes",                                       array: true
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["id"], name: "index_users_on_id", using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["source_id"], name: "index_users_on_source_id", using: :btree
  add_index "users", ["token"], name: "index_users_on_token", unique: true, using: :btree
  add_index "users", ["type"], name: "index_users_on_type", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",       null: false
    t.string   "item_id",         null: false
    t.string   "event",           null: false
    t.string   "whodunnit"
    t.text     "object"
    t.text     "object_changes"
    t.datetime "created_at"
    t.text     "meta"
    t.string   "event_type"
    t.text     "object_after"
    t.integer  "associated_id"
    t.string   "associated_type"
    t.integer  "team_id"
  end

  add_index "versions", ["associated_id"], name: "index_versions_on_associated_id", using: :btree
  add_index "versions", ["event_type"], name: "index_versions_on_event_type", using: :btree
  add_index "versions", ["item_type", "item_id", "whodunnit"], name: "index_versions_on_item_type_and_item_id_and_whodunnit", using: :btree
  add_index "versions", ["team_id"], name: "index_versions_on_team_id", using: :btree

  add_foreign_key "accounts", "teams"
  add_foreign_key "project_medias", "users"
  add_foreign_key "project_sources", "users"
  add_foreign_key "sources", "teams"
  add_foreign_key "users", "sources"
end
