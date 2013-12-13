class CreateAsyncMessages < ActiveRecord::Migration
  def self.up
    create_table :async_messages do |t|
      t.string :async_type
      t.integer :async_id
      t.string :params
      t.timestamps
    end
  end

  def self.down
    drop_table :async_messages
  end
end
