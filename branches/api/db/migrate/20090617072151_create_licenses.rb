class CreateLicenses < ActiveRecord::Migration
  def self.up
    create_table :licenses, :force => true do |t|
      t.string 'name'
      t.string 'domain'
      t.string 'url'
      t.timestamps
    end
  end

  def self.down
    drop_table :licenses
  end
end
