class Release < ActiveRecord::Base
  belongs_to :project
  has_many :fileentity
  #redis counter settings
  #acts_as_redis_counter :release_counter, :ttl => 5.minutes, :hits => 100
  def counter
    @counter ||= Counter.find(:item_id => self.id, :item_class => 'Release').first
    if @counter.nil?           
      @counter = Counter.create(:item_id => self.id,
                                :item_class => 'Release',
                                :item_counter_attribute => 'release_counter',
                                :flushed_at => Time.now.to_i)   
      @counter.incr(:counter, self.release_counter)             
    end
    @counter
  end 
  
  validates_format_of :version, :with => /^[0-9_\-a-zA-Z\.]{1,255}$/

  N_('PREPARING')
  N_('RELEASED')
  STATUS = { :PREPARING => 0, :RELEASED => 1}.freeze
  
  def self.status_to_s(int_status)
    _(STATUS.index(int_status).to_s)
  end
  def self.build_path(project_name, gid)
    gid = gid.to_i unless Integer===gid
    `/home/openfoundry/bin/create_dir #{gid+10000000} #{project_name}`
  end

  def self.top_download
    DownloadStatic.joins("INNER JOIN projects ON projects.name = download_statics.project").
                   select("project,SUM(count) as count_all,projects.summary,projects.icon,projects.id").
                   group("project").
                   where("projects.status = 2").
                   order("count_all desc").
                   limit(5)

  end

  def self.new_releases
    Release.joins(:project).where("releases.status = 1").where(Project.in_used_projects(:alias => "projects")).order("releases.created_at desc").limit(5)
  end

  def self.published_releases(options = {})
    a = options[:alias]
    if a;a += '.';end        
    "(#{a}status = 1)"    
  end

  def lock?
    (self.unlock_at.nil? || self.unlock_at < Date.today) ? false : true
  end

  scope :inactive, :conditions => ['status = 0']
  scope :active, :conditions => ['status = 1']
  scope :latest, :order => ['due desc']
end
