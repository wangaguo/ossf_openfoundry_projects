class CreateComponentLists < ActiveRecord::Migration
  def self.up
    create_table :component_lists do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :component_lists
  end
end
