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

ActiveRecord::Schema.define(version: 2022_03_18_123525) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "devices", force: :cascade do |t|
    t.string "uuid"
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_devices_on_uuid", unique: true
  end

  create_table "pictures", force: :cascade do |t|
    t.bigint "sensor_id", null: false
    t.string "file_name"
    t.string "file_url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "date_time"
    t.index ["sensor_id"], name: "index_pictures_on_sensor_id"
  end

  create_table "sensor_readings", force: :cascade do |t|
    t.integer "sensorvalue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "sensor_id"
    t.datetime "date_time"
    t.index ["sensor_id"], name: "index_sensor_readings_on_sensor_id"
  end

  create_table "sensor_types", force: :cascade do |t|
    t.string "name"
    t.string "unit"
    t.integer "pow10multi"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sensors", force: :cascade do |t|
    t.string "uuid"
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "device_id"
    t.bigint "sensor_type_id"
    t.index ["device_id"], name: "index_sensors_on_device_id"
    t.index ["sensor_type_id"], name: "index_sensors_on_sensor_type_id"
    t.index ["uuid"], name: "index_sensors_on_uuid", unique: true
  end

  add_foreign_key "pictures", "sensors"
  add_foreign_key "sensor_readings", "sensors"
  add_foreign_key "sensors", "devices"
  add_foreign_key "sensors", "sensor_types"
end
