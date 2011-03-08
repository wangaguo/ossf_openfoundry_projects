class Release < ActiveRecord::Base
  belongs_to :project
  has_many :fileentity
  #redis counter settings
  acts_as_redis_counter :release_counter, :ttl => 5.minutes, :hits => 100
  
  validates_format_of :version, :with => /^[0-9_\-a-zA-Z\.]{1,255}$/

  #add fulltext indexed SEARCH
  #acts_as_ferret({ :fields => { 
  #                            :name => { :boost => 1.5,
  #                                        :store => :yes
  #                                        },
  #                            :description => { :store => :yes,
  #                                           :index => :yes }                                                         
  #                          },
  #               :single_index => true
  #               },{ :analyzer => GENERIC_ANALYZER, :default_field => DEFAULT_FIELD })
  N_('PREPARING')
  N_('RELEASED')
  STATUS = { :PREPARING => 0, :RELEASED => 1}.freeze
  
  #def should_be_indexed?
  #  self.status == Release::STATUS[:RELEASED]
  #end
  #def ferret_enabled?(is_bulk_index = false)
  #  should_be_indexed? && #super(is_bulk_index) # TODO: super will cause recursive call..
  #    (@ferret_disabled.nil? && (is_bulk_index || self.class.ferret_enabled?))
  #end
  #def destroy_ferret_index_when_not_ready
  #  ferret_destroy if not should_be_indexed?
  #end
  #after_save :destroy_ferret_index_when_not_ready
  
  def self.status_to_s(int_status)
    _(STATUS.index(int_status).to_s)
  end
  def self.build_path(project_name, gid)
    gid = gid.to_i unless Integer===gid
    `/home/openfoundry/bin/create_dir #{gid+10000000} #{project_name}`
  end

  def self.top_download
    Release.joins(:project).find(:all, :group => 'project_id', :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "MAX(release_counter) DESC", :limit => 5)
  end

  def self.new_releases
    Release.joins(:project).find(:all, :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "releases.created_at desc", :limit => 5)
  end

  def self.published_releases(options = {})
    a = options[:alias]
    if a;a += '.';end        
    "(#{a}status = 1)"    
  end

  scope :inactive, :conditions => ['status = 0']
  scope :active, :conditions => ['status = 1']
  scope :latest, :order => ['due desc']
end
