class CreateTables < ActiveRecord::Migration
  def self.up
    create_table "categories", :force => true do |t|
      t.string   "name"
      t.integer  "parent"
      t.integer  "creator"
      t.string   "description"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at"
      t.integer  "updated_by"
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
      t.integer  "updated_by"
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
      t.integer  "updated_by"
    end

    create_table "images", :force => true do |t|
      t.string "name",    :default => "upload_img", :null => false
      t.string "meta"
      t.string "comment"
      t.binary "data",  :size => 2**24
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
      t.integer  "updated_by"
    end
    
    create_table "jobs", :force => true do |t|
      t.string   "subject",     :limit => 255,  :default => "", :null => false
      t.string   "description", :limit => 4000, :default => "", :null => false
      t.string   "requirement", :limit => 255,  :default => "", :null => false
      t.datetime "due",                                         :null => true
      t.integer  "project_id",                  :default => 0,  :null => false
      t.integer  "status",                      :default => 1,  :null => false
      t.integer  "creator",                     :default => 0,  :null => false
      t.datetime "created_at",                                  :null => false
      t.datetime "updated_at",                                  :null => false
      t.integer  "updated_by"
    end
    
    create_table "citations", :force => true do |t|
      t.string   "primary_authors",  :limit => 255,  :default => "", :null => false
      t.string   "project_title",    :limit => 255,  :default => "", :null => false
      t.string   "license",          :limit => 255,  :default => "", :null => false
      t.string   "url",              :limit => 255,  :default => "", :null => false
      t.datetime "release_date",                                     :null => true
      t.string   "release_version",  :limit => 255,  :default => "", :null => false
      t.integer  "project_id",                       :default => 0,  :null => false
      t.integer  "status",                           :default => 1,  :null => false
      t.integer  "creator",                          :default => 0,  :null => false
      t.datetime "created_at",                                       :null => false
      t.datetime "updated_at",                                       :null => false
      t.integer  "updated_by"
    end
    
    create_table "references", :force => true do |t|
      t.string   "source",     :limit => 4000,  :default => "", :null => false
      t.integer  "project_id",                  :default => 0,  :null => false
      t.integer  "status",                      :default => 1,  :null => false
      t.integer  "creator",                     :default => 0,  :null => false
      t.datetime "created_at",                                  :null => false
      t.datetime "updated_at",                                  :null => false
      t.integer  "updated_by"
    end
    
    create_table "events", :force => true do |t|
      t.string   "subject",    :limit => 255,  :default => "", :null => false
      t.datetime "starts",                                     :null => true
      t.datetime "due",                                        :null => true
      t.integer  "owner",                      :default => 0,  :null => false
      t.string   "version",    :limit => 255,  :default => "", :null => false
      t.integer  "project_id",                 :default => 0,  :null => false
      t.integer  "creator",                    :default => 0,  :null => false
      t.datetime "created_at",                                 :null => false
      t.datetime "updated_at",                                 :null => false
      t.integer  "updated_by"
    end

    create_table "downloaders", :force => true do |t|
      t.string   "name",       :limit => 255,  :default => "", :null => false
      t.string   "email",      :limit => 255,  :default => "", :null => false
      t.string   "purpose",    :limit => 255,  :default => "", :null => false
      t.string   "homepage",   :limit => 255,  :default => "", :null => false
      t.string   "citation",   :limit => 255,  :default => "", :null => false
      t.string   "contact",    :limit => 255,  :default => "", :null => false
      t.string   "occupation", :limit => 255,  :default => "", :null => false
      t.string   "age",        :limit => 255,  :default => "", :null => false
      t.string   "interests",  :limit => 255,  :default => "", :null => false
      t.string   "skills",     :limit => 255,  :default => "", :null => false
      t.string   "file",       :limit => 155,  :default => "", :null => false
      t.integer  "project_id",                 :default => 0,  :null => false
      t.integer  "creator",                    :default => 0,  :null => false
      t.datetime "created_at",                                 :null => false
      t.datetime "updated_at",                                 :null => false
      t.integer  "updated_by"
    end

    # see also: app/models/project.rb
    # the limit is specified in lengh of unicode characters, not bytes
    create_table "projects", :force => true do |t|
      t.integer "icon",                :default => 0, :null => false
      t.string  "name",                :limit => 15, :null => false
      t.string  "summary",             :limit => 255
      t.text    "rationale"            # backward compatibility
      t.text    "description"
      t.string  "contactinfo",         :limit => 255
      t.integer "maturity"
      t.string  "license",             :limit => 50
      t.string  "contentlicense",      :limit => 50
      t.text    "licensingdescription"
      t.string  "platform",            :limit => 100
      t.string  "programminglanguage", :limit => 100 
      t.string  "intendedaudience"     # backward compatibility
      t.string  "redirecturl",         :limit => 255
      t.integer "vcs"
      t.string  "vcsdescription",      :limit => 100

      t.integer "creator"
      t.integer "status"
      t.text    "statusreason"
      t.integer "project_counter",     :default => 0, :null => false
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
      t.integer  "updated_by"
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
      t.integer  "updated_by"
    end

    create_table "roles", :force => true do |t|
      t.string   "name",              :limit => 40
      t.string   "authorizable_type", :limit => 30
      t.integer  "authorizable_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "creator"
      t.integer  "updated_by"
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

    create_table :sessions, :force => true do |t|
      t.string :session_id, :null => false
      t.string :host, :null => false
      t.integer :user_id
      t.text :data
      t.timestamps
    end

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
    add_index :sessions, :user_id
 
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
      t.string   "realname",        :limit => 40
      t.string   "homepage",        :limit => 255
      t.string   "bio",             :limit => 1023
      t.string   "identity_url",    :limit => 255
      t.string   "salt",            :limit => 40, :default => "", :null => false
      t.integer  "verified",                      :default => 0
      t.string   "role",            :limit => 40
      t.string   "security_token",  :limit => 40
      t.datetime "token_expiry"
      t.integer  "status",         :default => 0
      t.datetime "delete_after"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "logged_in_at"
      t.string   "language",        :limit => 5
      t.string   "timezone",        :limit => 40, :default => "Taipei"
    end
    add_index "users", ["login", "salted_password"], :name => "index_users_on_login_pass"
    add_index "users", ["identity_url"], :name => "index_users_on_identity_url"

    #for openid support, see vender/plugins/...openid.../README
    create_table :open_id_authentication_associations, :force => true do |t|
      t.integer :issued, :lifetime
      t.string :handle, :assoc_type
      t.binary :server_url, :secret
    end

    create_table :open_id_authentication_nonces, :force => true do |t|
      t.integer :timestamp, :null => false
      t.string :server_url, :null => true
      t.string :salt, :null => false
    end
  end

  def self.down
    %w(users projects tags taggings categories
    sessions roles roles_users roles_functions functions
    releases news jobs citations references events 
    downloaders fileentities images 
    open_id_authentication_associations 
    open_id_authentication_nonces ).each do |table_name|
      drop_table table_name
    end
  end
end
