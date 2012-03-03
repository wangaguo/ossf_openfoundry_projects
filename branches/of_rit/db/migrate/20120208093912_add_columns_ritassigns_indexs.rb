class AddColumnsRitassignsIndexs < ActiveRecord::Migration
  def self.up
   add_index :ritassigns, :asRitID
  add_index :ritassigns, :asUserID
  end

  def self.down
  end
end
