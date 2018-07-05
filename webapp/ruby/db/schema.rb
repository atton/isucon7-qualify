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

ActiveRecord::Schema.define(version: 0) do

  create_table "channel", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.text "name", null: false
    t.text "description", limit: 16777215
    t.datetime "updated_at", null: false
    t.datetime "created_at", null: false
  end

  create_table "haveread", primary_key: ["user_id", "channel_id"], options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "channel_id", null: false
    t.bigint "message_id"
    t.datetime "updated_at", null: false
    t.datetime "created_at", null: false
  end

  create_table "image", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name", limit: 191
    t.binary "data", limit: 4294967295
  end

  create_table "message", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.bigint "channel_id"
    t.bigint "user_id"
    t.text "content"
    t.datetime "created_at", null: false
  end

  create_table "user", id: :bigint, unsigned: true, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "name", limit: 191
    t.string "salt", limit: 20
    t.string "password", limit: 40
    t.text "display_name"
    t.text "avatar_icon"
    t.datetime "created_at", null: false
    t.index ["name"], name: "name", unique: true
  end

end
