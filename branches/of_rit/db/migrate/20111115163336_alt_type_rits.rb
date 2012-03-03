class AltTypeRits < ActiveRecord::Migration
  def self.up
    change_column :rits , :ticketType , :integer
    remove_column :rits, :attach_path
  end

  def self.down
  end
end
