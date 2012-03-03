class AltColunmRitfiles < ActiveRecord::Migration
  def self.up
    add_column :ritfiles, :fromRit, :integer , :default => 0
    add_column :ritfiles, :fromReplay, :integer , :default => 0
  end

  def self.down
  end
end
