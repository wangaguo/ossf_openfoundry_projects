class AddColumnRits < ActiveRecord::Migration
  def self.up
   add_column :rits ,:priority ,:integer
  end

  def self.down
  end
end
