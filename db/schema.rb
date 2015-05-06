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

ActiveRecord::Schema.define(version: 20150429144750) do

  create_table "announcements", force: :cascade do |t|
    t.string  "title"
    t.text    "contents"
    t.string  "author"
    t.date    "posted_date"
    t.integer "week_id"
  end

  add_index "announcements", ["week_id"], name: "index_announcements_on_week_id"

  create_table "bulletins", force: :cascade do |t|
    t.string   "title"
    t.datetime "posted_on"
    t.datetime "expired_on"
    t.string   "author"
    t.string   "url"
    t.string   "contents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subject_classes", force: :cascade do |t|
    t.string  "class_number"
    t.string  "section"
    t.string  "component"
    t.integer "subject_id"
  end

  create_table "subject_files", force: :cascade do |t|
    t.string  "file_name"
    t.string  "token"
    t.string  "content_id"
    t.string  "content_type"
    t.string  "file_path"
    t.integer "subject_id"
    t.integer "announcement_id"
  end

  add_index "subject_files", ["announcement_id"], name: "index_subject_files_on_announcement_id"
  add_index "subject_files", ["subject_id"], name: "index_subject_files_on_subject_id"

  create_table "subjects", force: :cascade do |t|
    t.string "status"
    t.string "name"
  end

  create_table "timeslots", force: :cascade do |t|
    t.string  "day"
    t.string  "start_time"
    t.string  "end_time"
    t.string  "venue"
    t.integer "subject_class_id"
  end

  create_table "weeks", force: :cascade do |t|
    t.integer "subject_id"
    t.string  "title"
  end

  add_index "weeks", ["subject_id"], name: "index_weeks_on_subject_id"

end
