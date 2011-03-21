class CreateProjectLists < ActiveRecord::Migration
  def self.up
    create_table :project_lists do |t|
      t.integer :project_id
      t.text :user_name
      t.integer :order
      t.timestamps
    end
  end

  def self.down
    drop_table :project_lists
  end
end
