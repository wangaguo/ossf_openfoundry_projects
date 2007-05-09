# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 4) do

  create_table "projects", :force => true do |t|
    t.column "unixname",            :string
    t.column "projectname",         :string
    t.column "rationale",           :text
    t.column "publicdescription",   :text
    t.column "contactinfo",         :string
    t.column "maturity",            :string
    t.column "license",             :string
    t.column "contentlicense",      :string
    t.column "platform",            :string
    t.column "programminglanguage", :string
    t.column "intendedaudience",    :string
    t.column "redirecturl",         :string
    t.column "vcs",                 :string
    t.column "remotevcs",           :string
  end

  create_table "roles", :force => true do |t|
    t.column "name",              :string,   :limit => 40
    t.column "authorizable_type", :string,   :limit => 30
    t.column "authorizable_id",   :integer
    t.column "created_at",        :datetime
    t.column "updated_at",        :datetime
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.column "user_id",    :integer
    t.column "role_id",    :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "sessions", :force => true do |t|
    t.column "session_id", :string,   :limit => 32, :default => "", :null => false
    t.column "user_id",    :integer
    t.column "host",       :string,   :limit => 20
    t.column "created_at", :datetime,                               :null => false
    t.column "updated_at", :datetime,                               :null => false
    t.column "data",       :text
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id", :unique => true
  add_index "sessions", ["user_id"], :name => "index_sessions_on_user_id"
  add_index "sessions", ["host"], :name => "index_sessions_on_host"
  add_index "sessions", ["created_at"], :name => "index_sessions_on_created_at"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.column "login",           :string,   :limit => 80, :default => "", :null => false
    t.column "salted_password", :string,   :limit => 40, :default => "", :null => false
    t.column "email",           :string,   :limit => 60, :default => "", :null => false
    t.column "firstname",       :string,   :limit => 40
    t.column "lastname",        :string,   :limit => 40
    t.column "salt",            :string,   :limit => 40, :default => "", :null => false
    t.column "verified",        :integer,                :default => 0
    t.column "role",            :string,   :limit => 40
    t.column "security_token",  :string,   :limit => 40
    t.column "token_expiry",    :datetime
    t.column "deleted",         :integer,                :default => 0
    t.column "delete_after",    :datetime
    t.column "created_at",      :datetime
    t.column "updated_at",      :datetime
    t.column "logged_in_at",    :datetime
  end

end
