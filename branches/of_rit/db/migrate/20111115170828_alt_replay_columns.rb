class AltReplayColumns < ActiveRecord::Migration
  def self.up
    rename_column :ritreplies, :status, :replytype
    remove_column :ritreplies , :attach_path
  end

  def self.down
  end
end
