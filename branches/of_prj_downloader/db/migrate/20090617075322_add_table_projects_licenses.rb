class AddTableProjectsLicenses < ActiveRecord::Migration
  def self.up
    create_table "projects_licenses", :id => false, :force => true do |t|
      t.integer  "project_id"
      t.integer  "license_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "projects_licenses", ["project_id"], :name => "index_license_on_p"
    add_index "projects_licenses", ["license_id"], :name => "index_license_on_l"
  end

  def self.down
      drop_table "projects_licenses"
  end
end
