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

ActiveRecord::Schema.define(:version => 20120330034833) do

  create_table "archived_counter_logs", :force => true do |t|
    t.integer  "project_id"
    t.integer  "release_id"
    t.integer  "file_entity_id"
    t.string   "ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "archived_counter_logs", ["project_id", "release_id", "file_entity_id"], :name => "archived_counter_logs_prf"

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.integer  "parent"
    t.integer  "creator"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at"
    t.integer  "updated_by"
  end

  create_table "citations", :force => true do |t|
    t.string   "primary_authors", :default => "", :null => false
    t.string   "project_title",   :default => "", :null => false
    t.string   "license",         :default => "", :null => false
    t.string   "url",             :default => "", :null => false
    t.datetime "release_date"
    t.string   "release_version", :default => "", :null => false
    t.integer  "project_id",      :default => 0,  :null => false
    t.integer  "status",          :default => 1,  :null => false
    t.integer  "creator",         :default => 0,  :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "updated_by"
  end

  create_table "downloaders", :force => true do |t|
    t.string   "name",                         :default => "", :null => false
    t.string   "email",                        :default => "", :null => false
    t.string   "purpose",                      :default => "", :null => false
    t.string   "homepage",                     :default => "", :null => false
    t.string   "citation",                     :default => "", :null => false
    t.string   "contact",                      :default => "", :null => false
    t.string   "occupation",                   :default => "", :null => false
    t.string   "age",                          :default => "", :null => false
    t.string   "interests",                    :default => "", :null => false
    t.string   "skills",                       :default => "", :null => false
    t.integer  "project_id",                   :default => 0,  :null => false
    t.integer  "creator",                      :default => 0,  :null => false
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
    t.integer  "updated_by"
    t.string   "file",          :limit => 155
    t.integer  "fileentity_id"
    t.integer  "user_id"
    t.integer  "release_id"
  end

  add_index "downloaders", ["fileentity_id"], :name => "index_on_downloader_fileentity_id"
  add_index "downloaders", ["project_id"], :name => "index_on_downloader_project_id"
  add_index "downloaders", ["release_id"], :name => "index_on_downloader_release_id"
  add_index "downloaders", ["user_id"], :name => "index_on_downloader_user_id"

  create_table "events", :force => true do |t|
    t.string   "subject",    :default => "", :null => false
    t.datetime "starts"
    t.datetime "due"
    t.integer  "Owner",      :default => 0,  :null => false
    t.string   "version",    :default => "", :null => false
    t.integer  "project_id", :default => 0,  :null => false
    t.integer  "creator",    :default => 0,  :null => false
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
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
    t.integer  "status",       :default => 1,  :null => false
  end

  add_index "fileentities", ["file_counter"], :name => "index_fileentities_on_file_counter"
  add_index "fileentities", ["meta"], :name => "index_fileendities_on_meta"
  add_index "fileentities", ["path"], :name => "index_fileentities_on_path"

  create_table "functions", :force => true do |t|
    t.string   "name",        :limit => 50
    t.string   "module",      :limit => 20
    t.string   "description", :limit => 100
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "updated_by"
  end

  add_index "functions", ["module"], :name => "index_functions_on_module"
  add_index "functions", ["name"], :name => "index_functions_on_name"

  create_table "images", :force => true do |t|
    t.string "name",                          :default => "upload_img", :null => false
    t.string "meta"
    t.string "comment"
    t.binary "data",    :limit => 2147483647
  end

  create_table "jobs", :force => true do |t|
    t.string   "subject",                     :default => "", :null => false
    t.string   "description", :limit => 4000, :default => "", :null => false
    t.string   "requirement",                 :default => "", :null => false
    t.datetime "due"
    t.integer  "project_id",                  :default => 0,  :null => false
    t.integer  "status",                      :default => 1,  :null => false
    t.integer  "creator",                     :default => 0,  :null => false
    t.datetime "created_at",                                  :null => false
    t.datetime "updated_at",                                  :null => false
    t.integer  "updated_by"
  end

  create_table "licenses", :force => true do |t|
    t.string   "name"
    t.string   "domain"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "projects_count", :default => 0
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

  create_table "open_id_authentication_associations", :force => true do |t|
    t.integer "issued"
    t.integer "lifetime"
    t.string  "handle"
    t.string  "assoc_type"
    t.binary  "server_url"
    t.binary  "secret"
  end

  create_table "open_id_authentication_nonces", :force => true do |t|
    t.integer "timestamp",  :null => false
    t.string  "server_url"
    t.string  "salt",       :null => false
  end

  create_table "project_lists", :force => true do |t|
    t.integer  "project_id"
    t.text     "user_name"
    t.integer  "order"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_trees", :force => true do |t|
    t.text     "description"
    t.text     "json_data"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "projects", :force => true do |t|
    t.integer  "icon",                                :default => 0, :null => false
    t.string   "name",                 :limit => 15,                 :null => false
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
    t.string   "vcsdescription"
    t.integer  "creator"
    t.integer  "status"
    t.text     "statusreason"
    t.integer  "project_counter",                     :default => 0, :null => false
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "updated_by"
    t.integer  "category"
  end

  add_index "projects", ["name"], :name => "index_projects_on_name"
  add_index "projects", ["project_counter"], :name => "index_projects_on_project_counter"
  add_index "projects", ["status"], :name => "index_projects_on_status"
  add_index "projects", ["vcs"], :name => "index_projects_on_vcs"

  create_table "projects_licenses", :id => false, :force => true do |t|
    t.integer  "project_id"
    t.integer  "license_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "projects_licenses", ["license_id"], :name => "index_license_on_l"
  add_index "projects_licenses", ["project_id"], :name => "index_license_on_p"

  create_table "references", :force => true do |t|
    t.string   "source",     :limit => 4000, :default => "", :null => false
    t.integer  "project_id",                 :default => 0,  :null => false
    t.integer  "status",                     :default => 1,  :null => false
    t.integer  "creator",                    :default => 0,  :null => false
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.integer  "updated_by"
  end

  create_table "releases", :force => true do |t|
    t.integer  "icon",            :default => 0,  :null => false
    t.integer  "project_id",                      :null => false
    t.string   "name"
    t.string   "description"
    t.string   "version",         :default => "", :null => false
    t.date     "due"
    t.integer  "status",          :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator"
    t.integer  "release_counter", :default => 0,  :null => false
    t.integer  "updated_by"
  end

  add_index "releases", ["created_at"], :name => "index_releases_on_created_at"
  add_index "releases", ["release_counter"], :name => "index_releases_on_release_counter"
  add_index "releases", ["version"], :name => "index_releases_on_version"

  create_table "rit_carbon_copies", :force => true do |t|
    t.integer  "rit_id"
    t.integer  "blind"
    t.integer  "is_user"
    t.integer  "user_id"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rit_carbon_copies", ["rit_id"], :name => "index_rit_carbon_copies_on_rit_id"
  add_index "rit_carbon_copies", ["user_id"], :name => "index_rit_carbon_copies_on_user_id"

  create_table "rit_watchers", :force => true do |t|
    t.integer  "rit_id"
    t.integer  "is_user"
    t.integer  "user_id"
    t.integer  "notify"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rit_watchers", ["rit_id"], :name => "index_rit_watchers_on_rit_id"
  add_index "rit_watchers", ["user_id"], :name => "index_rit_watchers_on_user_id"

  create_table "ritassigns", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "asRitID"
    t.integer  "asUserID"
  end

  add_index "ritassigns", ["asRitID"], :name => "index_ritassigns_on_asRitID"
  add_index "ritassigns", ["asUserID"], :name => "index_ritassigns_on_asUserID"

  create_table "ritfiles", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "ritFK"
    t.text     "filename"
    t.integer  "fromRit",    :default => 0
    t.integer  "fromReply",  :default => 0
    t.string   "filetype"
    t.string   "OrigName"
  end

  add_index "ritfiles", ["ritFK"], :name => "index_ritfiles_on_ritFK"

  create_table "ritreplies", :force => true do |t|
    t.integer  "rit_fk_id"
    t.integer  "user_id"
    t.string   "title"
    t.text     "content"
    t.integer  "replytype"
    t.boolean  "visible"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "guestmail"
  end

  add_index "ritreplies", ["rit_fk_id"], :name => "index_ritreplies_on_rit_fk_id"
  add_index "ritreplies", ["user_id"], :name => "index_ritreplies_on_user_id"

  create_table "rits", :force => true do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.string   "title"
    t.text     "content"
    t.integer  "status"
    t.boolean  "visible"
    t.text     "platform"
    t.integer  "tickettype"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "assign_user_id"
    t.integer  "priority"
    t.string   "guestmail"
  end

  add_index "rits", ["assign_user_id"], :name => "index_rits_on_assign_user_id"
  add_index "rits", ["project_id"], :name => "index_rits_on_project_id"
  add_index "rits", ["user_id"], :name => "index_rits_on_user_id"

  create_table "rittages", :force => true do |t|
    t.string   "tag"
    t.integer  "rit_ids"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rittages", ["rit_ids"], :name => "index_rittages_on_rit_ids"
  add_index "rittages", ["tag"], :name => "index_rittages_on_tag"

  create_table "roles", :force => true do |t|
    t.string   "name",              :limit => 40
    t.string   "authorizable_type", :limit => 30
    t.integer  "authorizable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "creator"
    t.integer  "updated_by"
  end

  add_index "roles", ["authorizable_id"], :name => "index_roles_on_authorizable_id"
  add_index "roles", ["authorizable_type"], :name => "index_roles_on_authorizable_type"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "roles_functions", :id => false, :force => true do |t|
    t.integer  "role_id"
    t.integer  "function_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles_functions", ["role_id", "function_id"], :name => "index_roles_functions_on_all"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles_users", ["user_id", "role_id"], :name => "index_roles_users_on_all"

  create_table "schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.string   "host"
    t.integer  "user_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"
  add_index "sessions", ["user_id"], :name => "index_sessions_on_user_id"

  create_table "surveys", :force => true do |t|
    t.integer "fileentity_id"
    t.string  "resource",      :limit => 10, :default => "0"
    t.string  "prompt"
  end

  create_table "tagclouds", :force => true do |t|
    t.string   "name"
    t.integer  "tag_type"
    t.integer  "status"
    t.datetime "created_at"
    t.integer  "tagged"
    t.integer  "searched"
  end

  add_index "tagclouds", ["id"], :name => "index_tagclouds_on_id", :unique => true
  add_index "tagclouds", ["status"], :name => "index_tagclouds_on_status"
  add_index "tagclouds", ["tag_type"], :name => "index_tagclouds_on_tag_type"

  create_table "tagclouds_projects", :force => true do |t|
    t.integer "tagcloud_id"
    t.integer "project_id"
  end

  add_index "tagclouds_projects", ["project_id"], :name => "index_tagclouds_projects_on_project_id"
  add_index "tagclouds_projects", ["tagcloud_id", "project_id"], :name => "index_tagclouds_projects_on_tagcloud_id_and_project_id", :unique => true
  add_index "tagclouds_projects", ["tagcloud_id"], :name => "index_tagclouds_projects_on_tagcloud_id"

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

  create_table "tolk_locales", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tolk_locales", ["name"], :name => "index_tolk_locales_on_name", :unique => true

  create_table "tolk_phrases", :force => true do |t|
    t.text     "key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tolk_translations", :force => true do |t|
    t.integer  "phrase_id"
    t.integer  "locale_id"
    t.text     "text"
    t.text     "previous_text"
    t.boolean  "primary_updated", :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tolk_translations", ["phrase_id", "locale_id"], :name => "index_tolk_translations_on_phrase_id_and_locale_id", :unique => true

  create_table "users", :force => true do |t|
    t.integer  "icon",                            :default => 0,        :null => false
    t.string   "login",           :limit => 80,   :default => "",       :null => false
    t.string   "salted_password", :limit => 40,   :default => "",       :null => false
    t.string   "email",           :limit => 60,   :default => "",       :null => false
    t.string   "realname",        :limit => 40
    t.string   "homepage"
    t.string   "bio",             :limit => 1023
    t.string   "identity_url"
    t.string   "salt",            :limit => 40,   :default => "",       :null => false
    t.integer  "verified",                        :default => 0
    t.string   "role",            :limit => 40
    t.string   "security_token",  :limit => 40
    t.datetime "token_expiry"
    t.integer  "status",                          :default => 0
    t.datetime "delete_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.string   "language",        :limit => 5
    t.string   "timezone",        :limit => 40,   :default => "Taipei"
  end

  add_index "users", ["identity_url"], :name => "index_users_on_identity_url", :length => {"identity_url"=>"191"}
  add_index "users", ["login", "salted_password"], :name => "index_users_on_login_pass"

end
