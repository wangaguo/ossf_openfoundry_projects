# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2) do

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "parent"
    t.integer  "creator"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at"
  end

  create_table "fileentities", :force => true do |t|
    t.integer  "icon",         :default => 0,  :null => false
    t.integer  "release_id"
    t.string   "name"
    t.string   "description"
    t.integer  "size"
    t.string   "path",         :default => "", :null => false
    t.string   "meta"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator"
    t.integer  "file_counter", :default => 0,  :null => false
  end

  add_index "fileentities", ["path"], :name => "index_fileentities_path", :unique => true

  create_table "functions", :force => true do |t|
    t.string   "name",        :limit => 50
    t.string   "module",      :limit => 20
    t.string   "description", :limit => 100
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", :force => true do |t|
    t.string "name",    :default => "upload_img", :null => false
    t.string "meta"
    t.string "comment"
    t.binary "data"
  end

  create_table "news", :force => true do |t|
    t.string   "subject",     :limit => 100,  :default => "", :null => false
    t.string   "description", :limit => 4000, :default => "", :null => false
    t.string   "tags",        :limit => 100,  :default => "", :null => false
    t.integer  "catid",                       :default => 0,  :null => false
    t.integer  "status",                      :default => 1,  :null => false
    t.integer  "creator",                     :default => 0,  :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
  end

  create_table "projects", :force => true do |t|
    t.integer  "icon",                                :default => 0,  :null => false
    t.string   "name",                 :limit => 15,  :default => "", :null => false
    t.string   "summary"
    t.text     "rationale"
    t.text     "description"
    t.string   "contactinfo"
    t.integer  "maturity"
    t.string   "license",              :limit => 50
    t.string   "contentlicense",       :limit => 50
    t.text     "licensingdescription"
    t.string   "platform",             :limit => 100
    t.string   "programminglanguage",  :limit => 100
    t.string   "intendedaudience"
    t.string   "redirecturl"
    t.integer  "vcs"
    t.string   "vcsdescription",       :limit => 100
    t.integer  "creator"
    t.integer  "status"
    t.text     "statusreason"
    t.integer  "project_counter",                     :default => 0,  :null => false
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
  end

  create_table "releases", :force => true do |t|
    t.integer  "icon",            :default => 0,  :null => false
    t.integer  "project_id",                      :null => false
    t.string   "name"
    t.string   "description"
    t.string   "version",         :default => "", :null => false
    t.date     "due"
    t.integer  "status",          :default => 1,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator"
    t.integer  "release_counter", :default => 0,  :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 30
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator"
  end

  create_table "roles_functions", :id => false, :force => true do |t|
    t.integer  "role_id"
    t.integer  "function_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :default => "", :null => false
    t.string   "host",       :default => "", :null => false
    t.integer  "user_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"
  add_index "sessions", ["user_id"], :name => "index_sessions_on_user_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_all", :unique => true

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name"

  create_table "users", :force => true do |t|
    t.integer  "icon",                          :default => 0,  :null => false
    t.string   "login",           :limit => 80, :default => "", :null => false
    t.string   "salted_password", :limit => 40, :default => "", :null => false
    t.string   "email",           :limit => 60, :default => "", :null => false
    t.string   "firstname",       :limit => 40
    t.string   "lastname",        :limit => 40
    t.string   "salt",            :limit => 40, :default => "", :null => false
    t.integer  "verified",                      :default => 0
    t.string   "role",            :limit => 40
    t.string   "security_token",  :limit => 40
    t.datetime "token_expiry"
    t.integer  "status",                        :default => 0
    t.datetime "delete_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.string   "language",        :limit => 5
    t.string   "timezone",        :limit => 40
  end

end