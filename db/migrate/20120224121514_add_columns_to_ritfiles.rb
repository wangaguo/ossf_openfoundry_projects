class AddColumnsToRitfiles < ActiveRecord::Migration
  def self.up
    add_column :ritfiles, :filetype , :string
    add_column :ritfiles, :OrigName, :string
  end

  def self.down
  end
end
