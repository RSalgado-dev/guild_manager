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

ActiveRecord::Schema[8.1].define(version: 2026_01_13_158934) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "guilds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_guilds_on_name"
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
    t.bigint "guild_id", null: false
    t.bigint "squad_id"
    t.datetime "updated_at", null: false
    t.integer "xp_points", default: 0, null: false
    t.index ["discord_id"], name: "index_users_on_discord_id", unique: true
    t.index ["guild_id"], name: "index_users_on_guild_id"
    t.index ["squad_id"], name: "index_users_on_squad_id"
  end

  add_foreign_key "audit_logs", "guilds"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "roles", "guilds"
  add_foreign_key "squads", "guilds"
  add_foreign_key "squads", "users", column: "emblem_reviewed_by_id"
  add_foreign_key "squads", "users", column: "emblem_uploaded_by_id"
  add_foreign_key "squads", "users", column: "leader_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "guilds"
  add_foreign_key "users", "squads"
end
