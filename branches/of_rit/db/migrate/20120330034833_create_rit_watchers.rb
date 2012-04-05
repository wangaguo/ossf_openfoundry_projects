class CreateRitWatchers < ActiveRecord::Migration
  def self.up
    create_table :rit_watchers do |t|
      t.integer :rit_id
      t.integer :is_user
      t.integer :user_id
      t.integer :notify
      t.string  :email
      t.timestamps
    end
    add_index :rit_watchers, :rit_id
    add_index :rit_watchers,  :user_id
  end

  def self.down
    drop_table :rit_watchers
  end
end
