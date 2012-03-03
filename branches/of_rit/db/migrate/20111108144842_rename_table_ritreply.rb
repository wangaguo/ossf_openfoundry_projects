class RenameTableRitreply < ActiveRecord::Migration
  def self.up
    rename_table :ritreplays , :ritreplys
  end

  def self.down
  end
end
