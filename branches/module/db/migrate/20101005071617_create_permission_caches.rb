class CreatePermissionCaches < ActiveRecord::Migration
  def self.up
    create_table :permission_caches do |t|
      t.integer :user_id, :permission_id, :project_id

      t.timestamps
    end
  end

  def self.down
    drop_table :permission_caches
  end
end
