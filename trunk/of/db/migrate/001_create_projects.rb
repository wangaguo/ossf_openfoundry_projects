class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.column "unixname", :string
      t.column "projectname", :string
      t.column "rationale", :text
      t.column "publicdescription", :text
      t.column "contactinfo", :string
      t.column "maturity", :string
      t.column "license", :string
      t.column "contentlicense", :string
      t.column "platform", :string
      t.column "programminglanguage", :string
      t.column "intendedaudience", :string
      t.column "redirecturl", :string
      t.column "vcs", :string
      t.column "remotevcs", :string
    end
  end

  def self.down
    drop_table :projects
  end
end
