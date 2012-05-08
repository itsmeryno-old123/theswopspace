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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120507100006) do

  create_table "categories", :force => true do |t|
    t.string "description"
  end

  create_table "images", :force => true do |t|
    t.string  "filename"
    t.string  "content_type"
    t.binary  "binary_data"
    t.integer "imageable_id"
    t.string  "imageable_type"
    t.string  "imageguid"
  end

  create_table "items", :force => true do |t|
    t.string  "description"
    t.boolean "visible"
    t.integer "category_id"
    t.integer "user_id"
    t.string  "itemguid"
    t.boolean "itemsaved"
  end

  create_table "news", :force => true do |t|
    t.string   "description"
    t.datetime "date"
    t.string   "link"
  end

  create_table "nominations", :force => true do |t|
    t.integer "item_id"
    t.integer "user_id"
    t.integer "month"
    t.boolean "finished"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "value"
    t.datetime "ratingdate"
    t.integer  "rateable_id"
    t.string   "rateable_type"
    t.integer  "createdby"
  end

  create_table "swops", :force => true do |t|
    t.string   "initiator_user_id"
    t.string   "recipient_user_id"
    t.string   "send_items"
    t.string   "receive_items"
    t.datetime "swop_date"
    t.boolean  "declined"
    t.string   "swopguid"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "password_hash"
    t.string   "userid"
    t.boolean  "verified"
    t.string   "verifyguid"
    t.datetime "membersince"
    t.string   "email"
    t.string   "userguid"
  end

  create_table "votes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "nomination_id"
    t.datetime "date"
  end

end
