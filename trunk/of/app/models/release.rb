class Release < ActiveRecord::Base
  belongs_to :project
  has_many :fileentity
  
  def self.build_path(project_name, gid)
    tmp_umask = File::umask
    File::umask(007)
    #for ftp upload "prefix/project_name"
    prefix = Project::PROJECT_UPLOAD_PATH
    unless File.exist?(prefix)
        Dir.mkdir(prefix)
	#TODO add ACL control here
	`setfacl -d -m u::rwx,g::rwx,o::r-x,u:www:r-x #{prefix}`
	`setfacl -m u::rwx,g::rwx,o::r-x,u:www:r-x #{prefix}`
    end
    prefix = File.join(prefix, project_name)
    
    unless File.exist?(prefix)
        Dir.mkdir(prefix)
	`chgrp #{gid} #{prefix}`
    end
    
    #for web download "prefix/project_name"
    prefix = Project::PROJECT_DOWNLOAD_PATH
    Dir.mkdir(prefix) unless File.exist?(prefix)
    prefix = File.join(prefix, project_name)
    Dir.mkdir(prefix) unless File.exist?(prefix)    
    File::umask(tmp_umask)
  end
  def self.top_download
    Release.find(:all, :order => "release_counter desc", :limit => 5)
  end
end
