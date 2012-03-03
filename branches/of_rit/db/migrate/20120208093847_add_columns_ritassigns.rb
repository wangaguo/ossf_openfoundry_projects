class AddColumnsRitassigns < ActiveRecord::Migration
  def self.up
      add_column :ritassigns, :asRitID, :integer
      add_column :ritassigns, :asUserID, :integer
  end

  def self.down
  end
end
