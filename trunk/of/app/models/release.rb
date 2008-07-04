class Release < ActiveRecord::Base
  belongs_to :project
  has_many :fileentity
  
  #add fulltext indexed SEARCH
  acts_as_ferret({ :fields => { 
                              :name => { :boost => 1.5,
                                          :store => :yes
                                          },
                              :description => { :store => :yes,
                                             :index => :yes }                                                         
                            },
                 :single_index => true,
                 :default_field => [:name, :description]
                 },{ :analyzer => GENERIC_ANALYZER })
  
  def self.build_path(project_name, gid)
    `/home/openfoundry/bin/create_dir #{gid} #{project_name}`
  end

  def self.top_download
    Release.find(:all, :include => [:project], :conditions => Project.in_used_projects('true', :alias => "projects"), :order => "release_counter desc", :limit => 5)
  end
  def self.new_releases
    Release.find(:all, :include => [:project], :conditions => Project.in_used_projects('true', :alias => "projects"), :order => "releases.created_at desc", :limit => 5)
  end
end
