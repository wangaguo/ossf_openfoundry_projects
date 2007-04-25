class CreateProjectUsers < ActiveRecord::Migration
  def self.up
    create_table :project_users do |t|
      t.column :project_id, :integer
      t.column :user_id, :integer
      t.column :role, :string
    end
  end

  def self.down
    drop_table :project_users
  end
end
