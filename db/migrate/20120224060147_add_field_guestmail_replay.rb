class AddFieldGuestmailReplay < ActiveRecord::Migration
  def self.up
    add_column :ritreplies, :guestmail, :string
  end

  def self.down
  end
end
