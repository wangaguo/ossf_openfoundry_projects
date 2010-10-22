class CreateDataSets < ActiveRecord::Migration
  def self.up
    create_table :data_sets do |t|
      t.string :model, :columns, :with, :conditions, :as
      t.integer :module_id
      t.timestamps
    end
    add_index :data_sets, [ :as, :module_id ], :unique => true
    add_index :data_sets, [ :model ]
    add_index :data_sets, [ :as ]
  end

  def self.down
    drop_table :data_sets
  end
end
