class RenameColunmsRitfiles < ActiveRecord::Migration
  def self.up
    rename_column :ritfiles , :fromReplay , :fromReply
  end

  def self.down
  end
end
