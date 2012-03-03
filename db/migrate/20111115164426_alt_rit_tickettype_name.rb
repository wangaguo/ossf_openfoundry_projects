class AltRitTickettypeName < ActiveRecord::Migration
  def self.up
    rename_column :rits , :ticketType ,:tickettype
  end

  def self.down
  end
end
