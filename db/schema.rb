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

ActiveRecord::Schema[7.0].define(version: 2026_07_20_122100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attachments", id: :serial, force: :cascade do |t|
    t.integer "model_id"
    t.string "model_type"
    t.string "path"
    t.string "file_name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "audits", id: :serial, force: :cascade do |t|
    t.integer "model_id"
    t.string "model_type"
    t.string "from_status"
    t.string "to_status"
    t.string "content"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "desc"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "instance_categories", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "desc"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "code"
    t.index ["code"], name: "index_instance_categories_on_code"
  end

  create_table "instance_logs", id: :serial, force: :cascade do |t|
    t.integer "instance_id"
    t.string "file_name"
    t.string "file_path"
    t.integer "user_id"
    t.string "status"
    t.datetime "active_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "apply_at", precision: nil
    t.integer "develop_id"
    t.integer "flow_id"
    t.integer "active_id"
  end

  create_table "instance_organizations", id: :serial, force: :cascade do |t|
    t.integer "instance_id"
    t.integer "organization_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "instances", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "instance_no"
    t.string "color"
    t.string "norms"
    t.string "file_name"
    t.string "file_path"
    t.text "desc"
    t.integer "user_id"
    t.integer "last_user_id"
    t.datetime "last_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "active_at", precision: nil
    t.integer "file_user_id"
    t.integer "technology_id"
    t.string "ancestry"
    t.integer "instance_category_id"
    t.index ["ancestry"], name: "index_instances_on_ancestry"
  end

  create_table "instances_users", id: :serial, force: :cascade do |t|
    t.integer "instance_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "matters", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "desc"
    t.integer "user_id"
    t.integer "file_user_id"
    t.datetime "last_update_at", precision: nil
    t.string "file_path"
    t.string "file_name"
    t.boolean "agree"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "status", default: "circulation"
    t.integer "countersign_user_id"
    t.datetime "countersign_at", precision: nil
  end

  create_table "notices", id: :serial, force: :cascade do |t|
    t.integer "model_id"
    t.string "model_type"
    t.text "content"
    t.boolean "need_reply"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "title"
    t.integer "user_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "desc"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "ancestry"
    t.index ["ancestry"], name: "index_organizations_on_ancestry"
  end

  create_table "product_logs", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.string "file_name"
    t.string "file_path"
    t.integer "user_id"
    t.string "status"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "active_at", precision: nil
    t.datetime "apply_at", precision: nil
    t.integer "develop_id"
    t.integer "flow_id"
    t.integer "active_id"
  end

  create_table "product_organizations", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "organization_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "products", id: :serial, force: :cascade do |t|
    t.integer "category_id"
    t.string "name"
    t.string "product_no"
    t.string "color"
    t.string "norms"
    t.string "file_name"
    t.string "file_path"
    t.text "desc"
    t.integer "user_id"
    t.integer "last_user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_updated_at", precision: nil
    t.integer "file_user_id"
    t.datetime "active_at", precision: nil
    t.integer "technology_id"
  end

  create_table "products_instances", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "instance_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "products_users", id: :serial, force: :cascade do |t|
    t.integer "product_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "resources", id: :serial, force: :cascade do |t|
    t.string "action"
    t.string "target"
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "role_resources", id: :serial, force: :cascade do |t|
    t.integer "role_id"
    t.integer "resource_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "desc"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "technologies", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "no"
    t.string "name"
    t.datetime "valid_at", precision: nil
    t.text "desc"
    t.string "file_name"
    t.string "file_path"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "last_user_id"
    t.integer "file_user_id"
    t.datetime "active_at", precision: nil
  end

  create_table "technology_instances", id: :serial, force: :cascade do |t|
    t.integer "technology_id"
    t.integer "instance_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "technology_logs", id: :serial, force: :cascade do |t|
    t.integer "technology_id"
    t.string "file_name"
    t.string "file_path"
    t.integer "user_id"
    t.string "status"
    t.integer "develop_id"
    t.integer "flow_id"
    t.integer "active_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "active_at", precision: nil
    t.datetime "apply_at", precision: nil
  end

  create_table "user_matters", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "matter_id"
    t.boolean "agree"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "user_notices", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "notice_id"
    t.text "reply"
    t.boolean "readed"
    t.boolean "replied"
    t.datetime "replied_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "login"
    t.string "name"
    t.integer "role_id"
    t.integer "organization_id"
    t.string "phone"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "locale"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
