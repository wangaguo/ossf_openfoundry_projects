class CreateComponentConfigs < ActiveRecord::Migration
  def self.up
    create_table :component_configs do |t|
      t.integer :project_id, :component_id, :position
      t.string :status, :options
      t.timestamps
    end
    add_index :component_configs, [ :project_id ]
    add_index :component_configs, [ :component_id ]
    add_index :component_configs, [ :position ]
  end

  def self.down
    drop_table :component_configs
  end
end
