class CreateArchivedCounterLogs < ActiveRecord::Migration
  def self.up
    create_table :archived_counter_logs do |t|
      t.integer :project_id
      t.integer :release_id
      t.integer :file_entity_id
      t.string :ip
      t.timestamps
    end

    add_index :archived_counter_logs, [:project_id, :release_id, :file_entity_id], :name => 'archived_counter_logs_prf'
  end

  def self.down
    drop_table :archived_counter_logs
  end
end
