class Release < ActiveRecord::Base
  belongs_to :project
  has_many :fileentity
  
  def self.build_path(project_name, gid)
    `/home/openfoundry/bin/create_dir #{gid} #{project_name}`
  end

  def self.top_download
    Release.find(:all, :include => [:project], :order => "release_counter desc", :limit => 5)
  end
  def self.new_releases
    Release.find(:all, :include => [:project], :order => "releases.created_at desc", :limit => 5)
  end
end
