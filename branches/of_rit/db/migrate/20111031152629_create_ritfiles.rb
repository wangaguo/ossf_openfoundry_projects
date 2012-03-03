class CreateRitfiles < ActiveRecord::Migration
  def self.up
    create_table :ritfiles do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :ritfiles
  end
end
