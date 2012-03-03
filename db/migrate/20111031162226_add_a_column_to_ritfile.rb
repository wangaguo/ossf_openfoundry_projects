class AddAColumnToRitfile < ActiveRecord::Migration
  def self.up
   add_column :ritfiles, :ritFK, :integer
   add_column :ritfiles, :filename, :text
  end

  def self.down
  end
end
