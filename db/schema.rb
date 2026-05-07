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

ActiveRecord::Schema[7.2].define(version: 2026_05_07_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "x_access_token"
    t.string "x_refresh_token"
    t.string "x_uid"
    t.string "x_username"
    t.string "raindrop_api_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "x_bookmarks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "tweet_id", null: false
    t.string "author_id"
    t.string "author_username"
    t.string "author_name"
    t.text "text"
    t.datetime "tweeted_at"
    t.string "url"
    t.jsonb "entities", default: {}
    t.jsonb "public_metrics", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "tweet_id"], name: "index_x_bookmarks_on_user_id_and_tweet_id", unique: true
    t.index ["user_id"], name: "index_x_bookmarks_on_user_id"
  end

  add_foreign_key "x_bookmarks", "users"
end
