class CreateArchivedCounterLogs < ActiveRecord::Migration
  def self.up
    create_table :archived_counter_logs do |t|
      add_column :archived_counter_logs, :project_id, :integer
      add_column :archived_counter_logs, :release_id, :integer
      add_column :archived_counter_logs, :file_entity_id, :integer
      t.string :ip
      t.timestamps
    end

    add_index :archived_counter_logs, [:item_id, :item_type]
  end

  def self.down
    drop_table :archived_counter_logs
  end
end
