class CreateRitCarbonCopies < ActiveRecord::Migration
  def self.up
    create_table :rit_carbon_copies do |t|
      t.integer :rit_id
      t.integer :blind
      t.integer :is_user
      t.integer :user_id
      t.string  :email
      t.timestamps
    end
    add_index :rit_carbon_copies, :rit_id
    add_index :rit_carbon_copies, :user_id
  end

  def self.down
    drop_table :rit_carbon_copies
  end
end
