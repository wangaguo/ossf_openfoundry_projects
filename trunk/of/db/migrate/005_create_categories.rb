class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
	    t.column :name,	:string
	    t.column :parent,	:integer
	    t.column :creator,	:integer
	    t.column :description,	:string
	    t.column :created_at,	:datetime, :null => false
	    t.column :updated_at,	:datetime, :null => false
		         
    end
  end

  def self.down
    drop_table :categories
  end
end
