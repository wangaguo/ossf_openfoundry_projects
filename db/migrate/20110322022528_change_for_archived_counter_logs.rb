class ChangeForArchivedCounterLogs < ActiveRecord::Migration
  def self.up
    add_column :archived_counter_logs, :project_id, :integer
    add_column :archived_counter_logs, :release_id, :integer
    add_column :archived_counter_logs, :file_entity_id, :integer

    remove_column :archived_counter_logs, :item_id
    remove_column :archived_counter_logs, :item_type
  end

  def self.down
    add_column :archived_counter_logs, :item_id, :integer
    add_column :archived_counter_logs, :item_type, :integer

    remove_column :archived_counter_logs, :file_entity_id
    remove_column :archived_counter_logs, :release_id
    remove_column :archived_counter_logs, :project_id
  end
end
