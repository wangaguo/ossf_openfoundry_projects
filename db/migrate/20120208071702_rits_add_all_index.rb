class RitsAddAllIndex < ActiveRecord::Migration
  def self.up
    add_index :ritfiles , :ritFK
    
    add_index :rits , :project_id
    add_index :rits , :user_id
    add_index :rits ,  :assign_user_id

    add_index :ritreplies , :rit_fk_id
    add_index :ritreplies , :user_id

  end

  def self.down
  end
end
