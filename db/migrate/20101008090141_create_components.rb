class CreateComponents < ActiveRecord::Migration
  def self.up
    create_table :components do |t|
      t.integer :position, :status
      t.string :name, :description, :argument
      t.timestamps
    end
    add_index :components, [:name]
    add_index :components, [:position]
  end

  def self.down
    drop_table :components
  end
end
