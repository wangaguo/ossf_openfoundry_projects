class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.column :session_id,   :string,   :limit => 32, :null => false
      t.column :user_id,      :integer
      t.column :host,         :string,   :limit => 20
      t.column :created_at,   :datetime, :null => false
      t.column :updated_at,   :datetime, :null => false
      t.column :data,         :text
    end

    add_index :sessions, :session_id, :unique => true
    add_index :sessions, :user_id
    add_index :sessions, :host
    add_index :sessions, :created_at
    add_index :sessions, :updated_at
  end

  def self.down
    drop_table :sessions
  end
end
