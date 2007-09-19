class FileRepos < ActiveRecord::Migration
  def self.up
	  create_table :fileentities do |t|
	  	t.column "filename", :string
		t.column "size", :integer
		t.column "path", :string
		t.column "meta", :string
		t.column "createat", :date
		t.column "createby", :integer
		t.column "modifyat", :date

	  end
  end

  def self.down
	 drop_table :fileentities
  end
end
