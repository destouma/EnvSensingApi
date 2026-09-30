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

ActiveRecord::Schema[8.1].define(version: 2026_09_30_160200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.string "name", null: false
    t.string "scope", null: false
    t.string "token_digest", null: false
    t.datetime "last_used_at", precision: nil
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_keys_on_token_digest", unique: true
  end

  create_table "device_tokens", force: :cascade do |t|
    t.bigint "device_id", null: false
    t.string "token_digest", null: false
    t.string "name"
    t.datetime "last_used_at", precision: nil
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_device_tokens_on_device_id"
    t.index ["token_digest"], name: "index_device_tokens_on_token_digest", unique: true
  end

  create_table "devices", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["uuid"], name: "index_devices_on_uuid", unique: true
  end

  create_table "pictures", force: :cascade do |t|
    t.bigint "sensor_id", null: false
    t.string "file_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "date_time", precision: nil, null: false
    t.index ["sensor_id", "date_time", "id"], name: "index_pictures_on_sensor_id_and_date_time_and_id"
  end

  create_table "sensor_readings", force: :cascade do |t|
    t.bigint "value", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "sensor_id", null: false
    t.datetime "date_time", precision: nil, null: false
    t.index ["sensor_id", "date_time", "id"], name: "index_sensor_readings_on_sensor_id_and_date_time_and_id"
  end

  create_table "sensor_types", force: :cascade do |t|
    t.string "name", null: false
    t.string "unit", null: false
    t.integer "pow10multi", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_sensor_types_on_name", unique: true
  end

  create_table "sensors", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "device_id", null: false
    t.bigint "sensor_type_id", null: false
    t.index ["device_id"], name: "index_sensors_on_device_id"
    t.index ["sensor_type_id"], name: "index_sensors_on_sensor_type_id"
    t.index ["uuid"], name: "index_sensors_on_uuid", unique: true
  end

  add_foreign_key "device_tokens", "devices"
  add_foreign_key "pictures", "sensors"
  add_foreign_key "sensor_readings", "sensors"
  add_foreign_key "sensors", "devices"
  add_foreign_key "sensors", "sensor_types"
end
