class AltRits < ActiveRecord::Migration
  def self.up
  	remove_column :rits, :ticket_id
	add_column :rits, :pass_user_id, :integer
	rename_column :rits, :attach_id , :attach_path
	change_column :rits, :attach_path , :text
	change_column :rits, :ticketType , :string

  end

  def self.down
  end
end
