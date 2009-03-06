# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090306063138) do

  create_table "blog_entries", :force => true do |t|
    t.integer  "user_id",    :limit => 11
    t.string   "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "what"
    t.string   "where"
    t.float    "price"
    t.float    "original"
    t.integer  "twit_id",    :limit => 11
    t.float    "discount"
    t.float    "lat"
    t.float    "lng"
    t.string   "price_text"
  end

  add_index "blog_entries", ["id"], :name => "index_blog_entries_on_id", :unique => true
  add_index "blog_entries", ["twit_id"], :name => "index_blog_entries_on_twit_id", :unique => true
  add_index "blog_entries", ["user_id"], :name => "index_blog_entries_on_user_id"

  create_table "ratings", :force => true do |t|
    t.integer  "rating",        :limit => 11, :default => 0
    t.datetime "created_at",                                  :null => false
    t.string   "rateable_type", :limit => 15, :default => "", :null => false
    t.integer  "rateable_id",   :limit => 11, :default => 0,  :null => false
    t.integer  "user_id",       :limit => 11, :default => 0,  :null => false
  end

  add_index "ratings", ["user_id"], :name => "fk_ratings_user"

  create_table "subscriptions", :force => true do |t|
    t.integer  "user_id",    :limit => 11
    t.integer  "friend_id",  :limit => 11
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "requested",                :default => false
    t.boolean  "approved",                 :default => false
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",        :limit => 11
    t.integer  "taggable_id",   :limit => 11
    t.string   "taggable_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["context", "taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"
  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "uri"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "web_user_id",        :limit => 11
    t.float    "lat"
    t.float    "lng"
    t.string   "address"
    t.float    "rated"
    t.string   "ranked"
    t.boolean  "show_friends_only",                :default => false, :null => false
    t.boolean  "hide_blocked_users",               :default => true,  :null => false
  end

  add_index "users", ["id"], :name => "index_users_on_id", :unique => true

  create_table "web_users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.string   "password_reset_code",       :limit => 40
    t.boolean  "is_admin",                                 :default => false
  end

  add_index "web_users", ["id"], :name => "index_web_users_on_id", :unique => true
  add_index "web_users", ["login"], :name => "index_web_users_on_login", :unique => true

end
