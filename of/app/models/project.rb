class Project < ActiveRecord::Base
  has_many :roles, :foreign_key => "authorizable_id", :conditions => "authorizable_type='Project'"
  MATURITY = { :IDEA => 0, :PREALPHA => 1, :ALPHA => 2, :BETA => 3, :RELEASED => 4, :MATURE => 5, :STANDARD => 6 }.freeze
  dummy_fix_me = _("IDEA"), _("PREALPHA"), _("ALPHA"), _("BETA"), _("RELEASED"), _("MATURE"), _("STANDARD")
  LICENSES = [ "GPL", "LGPL", "BSD" ].freeze
  CONTENT_LICENSES = [ "CC", "KK" ].freeze
  VCS = { :NONE => 0, :CVS => 1, :SUBVERSION => 2, :REMOTE => -1 }.freeze
  dummy_fix_me = _("NONE"), _("CVS"), _("SUBVERSION"), _("REMOTE")
  PLATFORMS = [ "Windows", "FreeBSD", "Linux", "Java Environment" ].freeze
  PROGRAMMING_LANGUAGES = [ "C", "Java", "Perl", "Ruby" ].freeze
  INTENDED_AUDIENCE = [ "General Use", "Programmer", "System Administrator", "Education", "Researcher" ]
  STATUS = { :APPLYING => 0, :REJECTED => 1, :READY => 2, :SUSPENDED => 3 }.freeze
  #for releases ftp upload and web download...
  PROJECT_UPLOAD_PATH = OPENFOUNDRY_PROJECT_UPLOAD_PATH.freeze
  PROJECT_DOWNLOAD_PATH = "#{RAILS_ROOT}/public/download".freeze  
  
  def self.status_to_s(int_status)
    STATUS.index int_status
  end
  def self.maturity_to_s(int_maturity)
    MATURITY.index int_maturity
  end
  # Project.vcs_to_s(1)    or
  # Project.vcs_to_s(:CVS)
  def self.vcs_to_s(vcs) # int or symbol
    i = (Symbol === vcs) ? VCS[vcs] : vcs.to_i
    case i
    when VCS[:CVS]
      _("TODO: 使用 CVS 版本控制系統")
    when VCS[:SUBVERSION]
      _("TODO: 使用 Subversion 版本控制系統")
    when VCS[:REMOTE]
      _("TODO: 使用其他站台的版本控制系統")
    when VCS[:NONE]
      _("TODO: 不使用版本控制系統")
    else
      _("TODO: 系統錯誤, 請通知站台管理員")
    end
  end
  def vcs_to_s
    Project.vcs_to_s(vcs)
  end
  #validates_inclusion_of :license, :in => LICENSES

  #support Project-User relationship
  acts_as_authorizable

  #add fulltext indexed SEARCH
  acts_as_ferret({
                 :fields => { 
                              :name => { :boost => 1.5,
                                         :store => :yes
                                         },
                              :summary => { :store => :yes,
                                            :index => :yes },
                              :description => { :store => :yes,
                                                :index => :yes }                                                         
                            },
                 :single_index =>true,
                 :default_field => [:name, :summary, :description]
                 },{ :analyzer => GENERIC_ANALYZER })

  #add tags
  acts_as_taggable
  
  #model relationships
  has_many :releases
  # field validations...
  # see also: http://rt.openfoundry.org/Edit/Queues/CustomField/?Queue=4
  #
  # Don't forget to modify "db/migrate/001_create_tables.rb"
  # 
  # see: /activerecord-2.0.2/lib/active_record/validations.rb
  validates_format_of :name, :with => /^[a-z][0-9a-z]{2,14}$/, :message => _('TODO: 以英數字組成, 英文字母開頭, 長度不超過15個字')
  #validates_inclusion_of :license, :in => LICENSES
  #validates_inclusion_of :contentlicense, :in => CONTENT_LICENSES
  
  def admins
    has_admins
  end
  def members
    has_members
  end
  def set_role(role, user) # user obj, role string
    raise ArgumentError, "User: #{user.inspect} is not defined" unless User === user
#    Role.validates_role(role)
    user.has_role role, self 
  end

  # apply for a new project
  #
  # data:    a hash
  # creator: an User object
  # return: the newly created project object, the same with 'create'
  #         if anything goes worng, check rtn.errors / rtn.errors.empty?
  def self.apply(data, creator)
    data[:creator] = creator.id
    data[:status] = Project::STATUS[:APPLYING]

    returning Project.create(data) do |project|
      if project.errors.empty?
        ProjectNotify.deliver_applied_site_admin(project)
      end
    end
  end

  # reason: string
  def approve(reason)
    raise "current status is wrong: #{self.status}" if self.status != Project::STATUS[:APPLYING]
    self.status = Project::STATUS[:READY]
    self.statusreason = reason
    save
    # TODO: transaction / efficiency / constant
    set_role("Admin", User.find(self.creator))
    # TODO: hook / listener / callback / ...
    Release::build_path(self.name, self.id)
    ProjectNotify.deliver_approved(self)
  end
  # reason: string
  def reject(reason)
    raise "current status is wrong: #{self.status}" if self.status != Project::STATUS[:APPLYING]
    self.status = Project::STATUS[:REJECTED]
    self.statusreason = reason
    save
    ProjectNotify.deliver_rejected(self)
  end
  # reason: string
  def suspend(reason)
    raise "current status is wrong: #{self.status}" if self.status != Project::STATUS[:READY]
    self.status = Project::STATUS[:SUSPENDED]
    self.statusreason = reason
    save
    # TODO: notify by email
  end
  # reason: string
  def resume(reason)
    raise "current status is wrong: #{self.status}" if self.status != Project::STATUS[:SUSPENDED]
    self.status = Project::STATUS[:READY]
    self.statusreason = reason
    save
    # TODO: notify by email
  end

  # Project.find(:first, :conditions => Project.in_used_projects(['name = ?', 'openfoundry']))
  # Project.find(:first, :conditions => Project.in_used_projects("name = 'openfoundry'"))
  # Project.find(:first, :conditions => Project.in_used_projects())
  # Project.exists?(Project.in_used_projects(['name = ?', name]))
  def self.in_used_projects(condition = 'true')
    if condition.is_a?(String)
      "(#{condition}) and (status = #{Project::STATUS[:READY]} or status = #{Project::STATUS[:SUSPENDED]})"
    elsif condition.is_a?(Array)
      [ in_used_projects(condition[0]), *condition[1 .. -1] ]
    else
      raise "wrong usage!"
    end
  end

  # Project.new(:name => 'openfoundry').valid?
  def validate_on_create
    if Project.exists?(Project.in_used_projects(['name = ?', name]))
      errors.add(:name, _("'#{name}' has already been taken"))
    end
  end

  
  def self.new_projects
    Project.find(:all, :conditions => Project.in_used_projects(), :order => "created_at desc", :limit => 5)
  end
end
