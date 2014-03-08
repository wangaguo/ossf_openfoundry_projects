class CreateDownloadStatics < ActiveRecord::Migration
  def self.up
    create_table :download_statics do |t|
      t.string :project
      t.string :version
      t.integer :file
      t.date :date
      t.integer :count

      t.timestamps
    end
  end

  def self.down
    drop_table :download_statics
  end
end
