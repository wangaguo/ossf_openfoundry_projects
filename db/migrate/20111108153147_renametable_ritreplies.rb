class RenametableRitreplies < ActiveRecord::Migration
  def self.up
    rename_table :ritreplys ,:ritreplies
  end

  def self.down
  end
end
