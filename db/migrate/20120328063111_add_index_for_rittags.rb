class AddIndexForRittags < ActiveRecord::Migration
  def self.up
    add_index :rittages, :tag
    add_index :rittages, :rit_ids 
  end

  def self.down
  end
end
