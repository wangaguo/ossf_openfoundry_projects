class LicenseAddProjectsCount < ActiveRecord::Migration
  def self.up
    add_column :licenses, :projects_count, :integer, :default => 0
    License.reset_column_information
    License.find(:all).each do |l|
        l.update_attribute :projects_count, l.projects.length
    end
  end

  def self.down
    remove_column :licenses, :projects_count
  end
end
