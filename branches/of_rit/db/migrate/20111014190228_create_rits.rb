class CreateRits < ActiveRecord::Migration
  def self.up
    create_table :rits do |t|
    t.integer  :project_id
    t.integer  :ticket_id
    t.integer  :user_id
    t.string   :title
    t.text     :content
    t.integer  :status
    t.boolean  :visible
    t.text     :platform
    t.integer  :attach_id
    t.integer  :ticketType
    t.timestamps
    end
  end

  def self.down
    drop_table :rits
  end
end
