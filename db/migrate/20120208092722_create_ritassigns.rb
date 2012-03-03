class CreateRitassigns < ActiveRecord::Migration
  def self.up
    create_table :ritassigns do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :ritassigns
  end
end
