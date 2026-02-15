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

ActiveRecord::Schema[8.1].define(version: 2026_02_15_014546) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "guild_id", null: false
    t.string "icon_url"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["guild_id", "code"], name: "index_achievements_on_guild_id_and_code", unique: true
    t.index ["guild_id", "name"], name: "index_achievements_on_guild_id_and_name"
    t.index ["guild_id"], name: "index_achievements_on_guild_id"
  end

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.bigint "entity_id"
    t.string "entity_type"
    t.bigint "guild_id"
    t.jsonb "metadata", default: {}
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["entity_type", "entity_id"], name: "index_audit_logs_on_entity_type_and_entity_id"
    t.index ["guild_id"], name: "index_audit_logs_on_guild_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "certificates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "guild_id", null: false
    t.string "icon_url"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["guild_id", "code"], name: "index_certificates_on_guild_id_and_code", unique: true
    t.index ["guild_id", "name"], name: "index_certificates_on_guild_id_and_name"
    t.index ["guild_id"], name: "index_certificates_on_guild_id"
  end

  create_table "currency_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "balance_after", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.jsonb "metadata", default: {}, null: false
    t.bigint "reason_id"
    t.string "reason_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_currency_transactions_on_created_at"
    t.index ["reason_type", "reason_id"], name: "index_currency_transactions_on_reason_type_and_reason_id"
    t.index ["user_id"], name: "index_currency_transactions_on_user_id"
  end

  create_table "event_participations", force: :cascade do |t|
    t.boolean "attended", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "rewarded_at"
    t.string "rsvp_status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id", "user_id"], name: "index_event_participations_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_event_participations_on_event_id"
    t.index ["user_id"], name: "index_event_participations_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id"
    t.text "description"
    t.datetime "ends_at"
    t.string "event_type", null: false
    t.bigint "guild_id", null: false
    t.integer "reward_currency", default: 0, null: false
    t.integer "reward_xp", default: 0, null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "scheduled", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["guild_id"], name: "index_events_on_guild_id"
    t.index ["starts_at"], name: "index_events_on_starts_at"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "game_characters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "level", null: false
    t.string "nickname", null: false
    t.integer "power", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_game_characters_on_user_id", unique: true
  end

  create_table "guilds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "discord_guild_id", null: false
    t.string "discord_icon_url"
    t.string "discord_name"
    t.string "name", null: false
    t.string "required_discord_role_id"
    t.string "required_discord_role_name"
    t.datetime "updated_at", null: false
    t.index ["discord_guild_id"], name: "index_guilds_on_discord_guild_id", unique: true
    t.index ["name"], name: "index_guilds_on_name"
  end

  create_table "mission_submissions", force: :cascade do |t|
    t.jsonb "answers_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.bigint "mission_id", null: false
    t.datetime "rewarded_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "week_reference", null: false
    t.index ["mission_id", "user_id", "week_reference"], name: "idx_on_mission_id_user_id_week_reference_1fc796d003", unique: true
    t.index ["mission_id"], name: "index_mission_submissions_on_mission_id"
    t.index ["user_id"], name: "index_mission_submissions_on_user_id"
    t.index ["week_reference"], name: "index_mission_submissions_on_week_reference"
  end

  create_table "missions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "frequency", default: "weekly", null: false
    t.bigint "guild_id", null: false
    t.string "name", null: false
    t.integer "reward_currency", default: 0, null: false
    t.integer "reward_xp", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["guild_id", "active"], name: "index_missions_on_guild_id_and_active"
    t.index ["guild_id"], name: "index_missions_on_guild_id"
  end

  create_table "role_certificate_requirements", force: :cascade do |t|
    t.bigint "certificate_id", null: false
    t.datetime "created_at", null: false
    t.boolean "required", default: true, null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["certificate_id"], name: "index_role_certificate_requirements_on_certificate_id"
    t.index ["role_id", "certificate_id"], name: "idx_on_role_id_certificate_id_f279b4b99a", unique: true
    t.index ["role_id"], name: "index_role_certificate_requirements_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "discord_role_id"
    t.bigint "guild_id", null: false
    t.boolean "is_admin", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["guild_id", "name"], name: "index_roles_on_guild_id_and_name", unique: true
    t.index ["guild_id"], name: "index_roles_on_guild_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "squads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.text "emblem_rejection_reason"
    t.datetime "emblem_reviewed_at"
    t.integer "emblem_reviewed_by_id"
    t.string "emblem_status", default: "none", null: false
    t.integer "emblem_uploaded_by_id"
    t.bigint "guild_id", null: false
    t.integer "leader_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["emblem_status"], name: "index_squads_on_emblem_status"
    t.index ["guild_id", "name"], name: "index_squads_on_guild_id_and_name", unique: true
    t.index ["guild_id"], name: "index_squads_on_guild_id"
    t.index ["leader_id"], name: "index_squads_on_leader_id"
  end

  create_table "user_achievements", force: :cascade do |t|
    t.bigint "achievement_id", null: false
    t.datetime "created_at", null: false
    t.datetime "earned_at", null: false
    t.bigint "source_id"
    t.string "source_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["achievement_id"], name: "index_user_achievements_on_achievement_id"
    t.index ["source_type", "source_id"], name: "index_user_achievements_on_source_type_and_source_id"
    t.index ["user_id", "achievement_id"], name: "index_user_achievements_on_user_id_and_achievement_id", unique: true
    t.index ["user_id"], name: "index_user_achievements_on_user_id"
  end

  create_table "user_certificates", force: :cascade do |t|
    t.bigint "certificate_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "granted_at", null: false
    t.bigint "granted_by_id"
    t.string "status", default: "granted", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["certificate_id"], name: "index_user_certificates_on_certificate_id"
    t.index ["status"], name: "index_user_certificates_on_status"
    t.index ["user_id", "certificate_id"], name: "index_user_certificates_on_user_id_and_certificate_id", unique: true
    t.index ["user_id"], name: "index_user_certificates_on_user_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "primary"
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "currency_balance", default: 0, null: false
    t.string "discord_access_token"
    t.string "discord_avatar_url"
    t.string "discord_id", null: false
    t.string "discord_nickname"
    t.string "discord_refresh_token"
    t.datetime "discord_token_expires_at"
    t.string "discord_username"
    t.string "email"
    t.bigint "guild_id", null: false
    t.boolean "has_guild_access", default: false, null: false
    t.boolean "is_admin", default: false, null: false
    t.bigint "squad_id"
    t.datetime "updated_at", null: false
    t.integer "xp_points", default: 0, null: false
    t.index ["discord_id"], name: "index_users_on_discord_id", unique: true
    t.index ["guild_id"], name: "index_users_on_guild_id"
    t.index ["squad_id"], name: "index_users_on_squad_id"
  end

  add_foreign_key "achievements", "guilds", on_delete: :cascade
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "guilds", on_delete: :cascade
  add_foreign_key "audit_logs", "users", on_delete: :cascade
  add_foreign_key "certificates", "guilds", on_delete: :cascade
  add_foreign_key "currency_transactions", "users", on_delete: :cascade
  add_foreign_key "event_participations", "events", on_delete: :cascade
  add_foreign_key "event_participations", "users", on_delete: :cascade
  add_foreign_key "events", "guilds", on_delete: :cascade
  add_foreign_key "events", "users", column: "creator_id", on_delete: :nullify
  add_foreign_key "game_characters", "users"
  add_foreign_key "mission_submissions", "missions", on_delete: :cascade
  add_foreign_key "mission_submissions", "users", on_delete: :cascade
  add_foreign_key "missions", "guilds", on_delete: :cascade
  add_foreign_key "role_certificate_requirements", "certificates", on_delete: :cascade
  add_foreign_key "role_certificate_requirements", "roles", on_delete: :cascade
  add_foreign_key "roles", "guilds", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "squads", "guilds", on_delete: :cascade
  add_foreign_key "squads", "users", column: "emblem_reviewed_by_id"
  add_foreign_key "squads", "users", column: "emblem_uploaded_by_id"
  add_foreign_key "squads", "users", column: "leader_id", on_delete: :cascade
  add_foreign_key "user_achievements", "achievements", on_delete: :cascade
  add_foreign_key "user_achievements", "users", on_delete: :cascade
  add_foreign_key "user_certificates", "certificates", on_delete: :cascade
  add_foreign_key "user_certificates", "users", column: "granted_by_id", on_delete: :nullify
  add_foreign_key "user_certificates", "users", on_delete: :cascade
  add_foreign_key "user_roles", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "users", on_delete: :cascade
  add_foreign_key "users", "guilds", on_delete: :cascade
  add_foreign_key "users", "squads", on_delete: :nullify
end
