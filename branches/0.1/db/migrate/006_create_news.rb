class News < ActiveRecord::Migration
  def self.up
     create_table :news do |t|
       t.column :subject, :string, :limit => 100, :null => false
       t.column :description, :string, :limit => 4000, :null => false
       t.column :tags, :string, :limit => 100, :default => "", :null => false
       t.column :catid, :integer, :default => 0, :null => false
       t.column :creator, :integer, :default => 0, :null => false
       t.column :created_at, :date, :null => false
       t.column :updated_at, :date, :null => false
     end
  end

  def self.down
    drop_table :news
  end
end
