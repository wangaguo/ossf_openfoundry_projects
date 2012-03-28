class CreateRittages < ActiveRecord::Migration
  def self.up
    create_table :rittages do |t|
      t.string :tag
      t.integer :rit_ids

      t.timestamps
    end
  end

  def self.down
    drop_table :rittages
  end
end
