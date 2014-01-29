class ReleaseLock < ActiveRecord::Migration
  def self.up
    add_column :releases, :unlock_at, :date
  end

  def self.down
    remove_column :releases, :unlock_at
  end
end
