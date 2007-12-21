class Release < ActiveRecord::Base
  belongs_to :project
  has_many :fileentity
  
  def self.build_path(project_name)
    #for ftp upload "prefix/project_name"
    prefix = Project::PROJECT_UPLOAD_PATH
    Dir.mkdir(prefix) unless File.directory?(prefix)
    prefix = File.join(prefix, project_name)
    Dir.mkdir(prefix) unless File.directory?(prefix)
    
    #for web download "prefix/project_name"
    prefix = Project::PROJECT_DOWNLOAD_PATH
    Dir.mkdir(prefix) unless File.directory?(prefix)
    prefix = File.join(prefix, project_name)
    Dir.mkdir(prefix) unless File.directory?(prefix)    
  end
end
