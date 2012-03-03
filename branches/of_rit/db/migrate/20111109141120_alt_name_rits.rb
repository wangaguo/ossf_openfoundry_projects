class AltNameRits < ActiveRecord::Migration
  def self.up
    rename_column :rits , :pass_user_id , :assign_user_id 
  end

  def self.down
  end
end
