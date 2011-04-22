class CreateArchivedCounterLogs < ActiveRecord::Migration
  def self.up
    create_table :archived_counter_logs do |t|
      t.references :item, :polymorphic => true
      t.string :ip
      t.timestamps
    end

    add_index :archived_counter_logs, [:item_id, :item_type]
  end

  def self.down
    drop_table :archived_counter_logs
  end
end
