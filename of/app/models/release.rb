class Release < ActiveRecord::Base
  belongs_to :project
  has_many :fileentity
  
  validates_format_of :version, :with => /^[0-9_\-a-zA-Z\.]{1,16}$/

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
  N_('PREPARING')
  N_('RELEASED')
  STATUS = { :PREPARING => 0, :RELEASED => 1}.freeze
  
  def should_be_indexed?
    self.status == Release::STATUS[:RELEASED]
  end
  def ferret_enabled?(is_bulk_index = false)
    should_be_indexed? && #super(is_bulk_index) # TODO: super will cause recursive call..
      (@ferret_disabled.nil? && (is_bulk_index || self.class.ferret_enabled?))
  end
  def destroy_ferret_index_when_not_ready
    ferret_destroy if not should_be_indexed?
  end
  after_save :destroy_ferret_index_when_not_ready
  
  def self.status_to_s(int_status)
    _(STATUS.index(int_status).to_s)
  end
  def self.build_path(project_name, gid)
    gid = gid.to_i unless Integer===gid
    `/home/openfoundry/bin/create_dir #{gid+10000000} #{project_name}`
  end

  def self.top_download
    Release.find(:all, :include => [:project], :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "release_counter desc", :limit => 5)
  end
  def self.new_releases
    Release.find(:all, :include => [:project], :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "releases.created_at desc", :limit => 5)
  end

  def self.published_releases(options = {})
    a = options[:alias]
    if a;a += '.';end        
    "(#{a}status = 1)"    
  end

  named_scope :inactive, :conditions => ['status = 0']
  named_scope :active, :conditions => ['status = 1']
end
