class ProjectsAddCategoryAndTags < ActiveRecord::Migration
  def self.up
    add_column :projects, :category, :integer
    Project.reset_column_information

    create_table :tagclouds do | t |
      t.string   :name
      t.integer  :tag_type		# the tag is a pure tag or a category ( 0: tag, 1: category )
      t.integer  :status			# the tag is pending or ready ( 0: pending, 1:ready )
      t.datetime :created_at
      t.integer  :tagged			# how many times of the tag is tagged
      t.integer  :searched    # how many times of the tag is searched 
    end
    add_index    :tagclouds, :id, :unique => true
    add_index    :tagclouds, :tag_type
    add_index    :tagclouds, :status

    create_table :tagclouds_projects do | t |
      t.integer  :tagcloud_id
      t.integer  :project_id
    end
    add_index    :tagclouds_projects, [ :tagcloud_id, :project_id ], :unique => true
    add_index    :tagclouds_projects, :tagcloud_id
    add_index    :tagclouds_projects, :project_id
  end

  def self.down
    drop_table :tagclouds_projects
    drop_table :tagclouds

    remove_column :projects, :category
  end
end
