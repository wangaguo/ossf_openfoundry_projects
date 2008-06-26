class Project < ActiveRecord::Base
  has_many :roles, :foreign_key => "authorizable_id", :conditions => "authorizable_type='Project'"

  # single selection 
  MATURITY = { :IDEA => 0, :PREALPHA => 1, :ALPHA => 2, :BETA => 3, :RELEASED => 4, :MATURE => 5, :STANDARD => 6 }.freeze
  dummy_fix_me = _("IDEA"), _("PREALPHA"), _("ALPHA"), _("BETA"), _("RELEASED"), _("MATURE"), _("STANDARD")

  # TODO

  LICENSE_DATA = <<"EOEO"
公共財(Public Domain)
專案不包含程式碼(This project contains no code)
OSI: Academic Free License
OSI: Affero GNU Public License
OSI: Adaptive Public License
OSI: Apache License 2.0
OSI: Artistic License 2.0
OSI: Attribution Assurance Licenses
OSI: New and Simplified BSD Licenses
OSI: Boost Software License (BSL1.0)
OSI: Common Development and Distribution License (CDDL)
OSI: Common Public Attribution License 1.0 (CPAL)
OSI: Common Public License 1.0
OSI: Eclipse Public License
OSI: Educational Community License 2.0
OSI: Eiffel Forum License 2.0
OSI: Fair License
OSI: GNU General Public License (GPL)
OSI: GNU General Public License 3.0 (GPLv3)
OSI: GNU Library or "Lesser" General Public License (LGPL)
OSI: GNU Library or "Lesser" General Public License 3.0 (LGPLv3)
OSI: ISC License
OSI: Lucent Public License 1.02
OSI: Microsoft Public License (Ms-PL)
OSI: Microsoft Reciprocal License (Ms-RL)
OSI: MIT License
OSI: Mozilla Public License 1.1 (MPL)
OSI: NASA Open Source Agreement 1.3
OSI: NTP License
OSI: Open Group Test Suite License
OSI: Open Software License
OSI: Qt Public License (QPL)
OSI: Simple Public License 2.0
OSI: Sleepycat License
OSI: University of Illinois/NCSA Open Source License
OSI: X.Net License
OSI: zlib/libpng License 
其他(Other licenses)
EOEO
  LICENSES = {}
  LICENSE_DATA.split("\n").each_with_index { |x, i| LICENSES[x.to_sym] = i }
  LICENSES.freeze

  CONTENT_LICENSES_DATA = <<"EOEO"
GNU Free Documentation License
Creative Commons: Attribution Non-commercial No Derivatives (by-nc-nd)
Creative Commons: Attribution Non-commercial Share Alike (by-nc-sa)
Creative Commons: Attribution Non-commercial (by-nc)
Creative Commons: Attribution No Derivatives (by-nd)
Creative Commons: Attribution Share Alike (by-sa)
Creative Commons: Attribution (by)
同程式碼(Same license as code)
公共財(Public Domain)
專案不包含圖文內容(Project contains only code)
其他(Other licenses)
EOEO
  CONTENT_LICENSES = {}
  CONTENT_LICENSES_DATA.split("\n").each_with_index { |x, i| CONTENT_LICENSES[x.to_sym] = i }
  CONTENT_LICENSES.freeze


  # see also: OpenFoundry.pm

  # single selection
  VCS = { :NONE => 0, :CVS => 1, :SUBVERSION => 2, :REMOTE => -1 }.freeze
  dummy_fix_me = _("NONE"), _("CVS"), _("SUBVERSION"), _("REMOTE")

  # mutiple selection + other (string,string,...)
  PLATFORMS = [ "Windows", "FreeBSD", "Linux", "Java Environment", ".NET Environment", "MacOSX", "MacOS Classic" ].freeze

  # mutiple selection + other (string,string,...)
  PROGRAMMING_LANGUAGES = [ "Assembly", "C", "C++", "Java", "Perl", "PHP", "Python", "Ruby" ].freeze

  # this field will only contains old values migrated from RT
  # INTENDED_AUDIENCE = [ "General Use", "Programmer", "System Administrator", "Education", "Researcher" ]
  
  #
  # important INTERNAL status
  #
  STATUS = { :APPLYING => 0, :REJECTED => 1, :READY => 2, :SUSPENDED => 3 }.freeze

  #for releases ftp upload and web download...
  PROJECT_UPLOAD_PATH = OPENFOUNDRY_PROJECT_UPLOAD_PATH.freeze
  PROJECT_DOWNLOAD_PATH = "#{RAILS_ROOT}/public/download".freeze  

  # name validation
  NAME_REGEX = /^[a-z][0-9a-z]{2,14}$/ # lengh = 15
  
  def self.status_to_s(int_status)
    _(STATUS.index(int_status).to_s)
  end
  def self.maturity_to_s(int_maturity)
    _(MATURITY.index(int_maturity).to_s)
  end
  def maturity_to_s
    Project.maturity_to_s(maturity)
  end
  def self.license_to_s(int_license)
    _(LICENSES.index(int_license).to_s)
  end
  def self.contentlicense_to_s(int_contentlicense)
    _(CONTENT_LICENSES.index(int_contentlicense).to_s)
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
  validates_format_of :name, :with => NAME_REGEX, :message => _('TODO: 以英數字組成, 英文字母開頭, 長度不超過15個字')
  validates_length_of :summary, :within => 3 ..255
  # rationale: only for backward compatibility
  # description: text
  validates_length_of :contactinfo, :maximum => 255
  validates_inclusion_of :maturity, :in => MATURITY.values
  validates_length_of :license, :maximum => 50; validates_format_of :license, :with => /,(\d+)*,/
  validates_length_of :contentlicense, :maximum => 50; validates_format_of :contentlicense, :with => /,(\d+)*,/
  validates_length_of :platform, :maximum => 100
  validates_length_of :programminglanguage, :maximum => 100
  # intendedaudience: only for backward compatibility
  validates_length_of :redirecturl, :maximum => 255 # TODO: should be a valid url! (and no loop)
  validates_inclusion_of :vcs, :in => VCS.values
  validates_length_of :vcsdescription, :maximum => 100

  
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

    # add default roles: Admin/Member
    ['Admin', 'Member'].each do |role_name|
      self.roles.new do |r|
        r.name = role_name 
        r.authorizable_type = 'Project'
        Role.set_default_privileges_for r
      end.save
    end

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
