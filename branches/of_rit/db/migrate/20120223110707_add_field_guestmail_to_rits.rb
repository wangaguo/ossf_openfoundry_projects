class AddFieldGuestmailToRits < ActiveRecord::Migration
  def self.up
    add_column :rits, :guestmail, :string
  end

  def self.down
  end
end
