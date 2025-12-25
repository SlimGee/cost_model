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

ActiveRecord::Schema[8.1].define(version: 2025_12_25_001327) do
  create_table "machines", force: :cascade do |t|
    t.decimal "annual_maintenance_cost"
    t.decimal "build_volume_x"
    t.decimal "build_volume_y"
    t.decimal "build_volume_z"
    t.datetime "created_at", null: false
    t.decimal "laser_power"
    t.integer "lifespan_years"
    t.string "model_number"
    t.string "name"
    t.decimal "purchase_price"
    t.decimal "scan_speed"
    t.datetime "updated_at", null: false
  end

  create_table "materials", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.decimal "density"
    t.decimal "embodied_carbon"
    t.string "name"
    t.decimal "raw_material_price"
    t.decimal "recycling_efficiency"
    t.datetime "updated_at", null: false
  end

  create_table "slicing_data", force: :cascade do |t|
    t.decimal "build_time_hours"
    t.datetime "created_at", null: false
    t.string "csv_file"
    t.decimal "layer_thickness"
    t.integer "machine_id"
    t.integer "material_id"
    t.decimal "material_utilization", default: "0.6"
    t.decimal "part_height"
    t.decimal "part_mass"
    t.string "part_name"
    t.decimal "part_volume"
    t.integer "parts_per_build", default: 1
    t.decimal "support_volume"
    t.decimal "surface_area"
    t.decimal "total_powder_mass"
    t.datetime "updated_at", null: false
    t.index ["machine_id"], name: "index_slicing_data_on_machine_id"
    t.index ["material_id"], name: "index_slicing_data_on_material_id"
  end

  add_foreign_key "slicing_data", "machines"
  add_foreign_key "slicing_data", "materials"
end
