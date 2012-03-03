class CreateRitreplays < ActiveRecord::Migration
  def self.up
    create_table :ritreplays do |t|
       	 t.integer  :rit_fk_id
         t.integer  :user_id
	 t.string   :title
	 t.text     :content
	 t.integer  :status
	 t.boolean  :visible
	 t.string   :attach_path

      t.timestamps
    end
  end

  def self.down
    drop_table :ritreplays
  end
end
