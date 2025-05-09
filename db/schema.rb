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

ActiveRecord::Schema[8.0].define(version: 2025_05_05_203323) do
  create_table "blob_trackers", id: { type: :string, limit: 26 }, force: :cascade do |t|
    t.string "blob_id", limit: 26
    t.integer "blob_size"
    t.string "storage_type"
    t.datetime "created_at"
    t.index ["blob_id"], name: "index_blob_trackers_on_blob_id", unique: true
    t.index ["id"], name: "index_blob_trackers_on_id", unique: true
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest"
    t.index ["user_id", "token_digest"], name: "index_refresh_tokens_on_user_id_and_token_digest"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "stored_blobs", id: { type: :string, limit: 26 }, force: :cascade do |t|
    t.binary "data"
    t.integer "size"
    t.datetime "created_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "refresh_tokens", "users"
end
