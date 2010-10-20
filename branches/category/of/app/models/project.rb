class Project < ActiveRecord::Base
  has_many :roles, :foreign_key => "authorizable_id", :conditions => "authorizable_type='Project'"

	# category association
	belongs_to :cattag, :class_name => 'Tagcloud', :foreign_key => 'category'
	# tagcloud association 
	has_and_belongs_to_many :tagclouds
	has_many :tagcloudsprojects, :foreign_key => :project_id

	# find the categorized projects
  named_scope :cated, lambda { | *args | { :conditions => [ 'category = ?', args.first ] } unless args.first.to_i == 0 }

  #redis counter settings
  acts_as_redis_counter :project_counter, :ttl => 5.minutes, :hits => 100

  # single selection 
  MATURITY = { :IDEA => 0, :PREALPHA => 1, :ALPHA => 2, :BETA => 3, :RELEASED => 4, :MATURE => 5, :STANDARD => 6 }.freeze
  N_("IDEA")
  N_("PREALPHA")
  N_("ALPHA")
  N_("BETA")
  N_("RELEASED")
  N_("MATURE")
  N_("STANDARD")


  # [ [1, "OSI: Academic Free License"],
  #   [2, "OSI: Affero GNU Public License"] ]
  # having mutiple spaces is ok
  # [ 34 OSI: X.Net License ] has been deleted at 2009.03.10
  LICENSE_DATA = <<"EOEO".split("\n").map {|x| (i, s) = x.split(" ", 2); [ i.to_i, s ] }
0 This project contains no code
-2 Public Domain
1 OSI: Academic Free License
2 OSI: GNU Affero General Public License v3 (AGPL3)
3 OSI: Adaptive Public License
4 OSI: Apache License 2.0
5 OSI: Artistic License 2.0
6 OSI: Attribution Assurance Licenses
7 OSI: BSD License (New and Simplified BSD License)
8 OSI: Boost Software License (BSL1.0)
9 OSI: Common Development and Distribution License (CDDL)
10 OSI: Common Public Attribution License 1.0 (CPAL)
11 OSI: Common Public License 1.0
12 OSI: Eclipse Public License
13 OSI: Educational Community License 2.0
14 OSI: Eiffel Forum License 2.0
15 OSI: Fair License
16 OSI: GNU General Public License 2.0 (GPLv2)
17 OSI: GNU General Public License 3.0 (GPLv3)
18 OSI: GNU Library or "Lesser" General Public License 2.1 (LGPLv2)
19 OSI: GNU Library or "Lesser" General Public License 3.0 (LGPLv3)
20 OSI: ISC License
21 OSI: Lucent Public License 1.02
22 OSI: Microsoft Public License (Ms-PL)
23 OSI: Microsoft Reciprocal License (Ms-RL)
24 OSI: MIT License
25 OSI: Mozilla Public License 1.1 (MPL)
26 OSI: NASA Open Source Agreement 1.3
27 OSI: NTP License
28 OSI: Open Group Test Suite License
29 OSI: Open Software License
30 OSI: Qt Public License (QPL)
31 OSI: Simple Public License 2.0
32 OSI: Sleepycat License
33 OSI: University of Illinois/NCSA Open Source License
35 OSI: zlib/libpng License
-1 Other licenses
EOEO
  # referenced by: licenses
  N_("url_link_for_OSI: Academic Free License")
  N_("url_link_for_OSI: GNU Affero General Public License v3 (AGPL3)")
  N_("url_link_for_OSI: Adaptive Public License")
  N_("url_link_for_OSI: Apache License 2.0")
  N_("url_link_for_OSI: Artistic License 2.0")
  N_("url_link_for_OSI: Attribution Assurance Licenses")
  N_("url_link_for_OSI: BSD License (New and Simplified BSD License)")
  N_("url_link_for_OSI: Boost Software License (BSL1.0)")
  N_("url_link_for_OSI: Common Development and Distribution License (CDDL)")
  N_("url_link_for_OSI: Common Public Attribution License 1.0 (CPAL)")
  N_("url_link_for_OSI: Common Public License 1.0")
  N_("url_link_for_OSI: Eclipse Public License")
  N_("url_link_for_OSI: Educational Community License 2.0")
  N_("url_link_for_OSI: Eiffel Forum License 2.0")
  N_("url_link_for_OSI: Fair License")
  N_("url_link_for_OSI: GNU General Public License 2.0 (GPLv2)")
  N_("url_link_for_OSI: GNU General Public License 3.0 (GPLv3)")
  N_("url_link_for_OSI: GNU Library or \"Lesser\" General Public License 2.1 (LGPLv2)")
  N_("url_link_for_OSI: GNU Library or \"Lesser\" General Public License 3.0 (LGPLv3)")
  N_("url_link_for_OSI: ISC License")
  N_("url_link_for_OSI: Lucent Public License 1.02")
  N_("url_link_for_OSI: Microsoft Public License (Ms-PL)")
  N_("url_link_for_OSI: Microsoft Reciprocal License (Ms-RL)")
  N_("url_link_for_OSI: MIT License")
  N_("url_link_for_OSI: Mozilla Public License 1.1 (MPL)")
  N_("url_link_for_OSI: NASA Open Source Agreement 1.3")
  N_("url_link_for_OSI: NTP License")
  N_("url_link_for_OSI: Open Group Test Suite License")
  N_("url_link_for_OSI: Open Software License")
  N_("url_link_for_OSI: Qt Public License (QPL)")
  N_("url_link_for_OSI: Simple Public License 2.0")
  N_("url_link_for_OSI: Sleepycat License")
  N_("url_link_for_OSI: University of Illinois/NCSA Open Source License")
  N_("url_link_for_OSI: zlib/libpng License")
  N_("url_link_for_GNU Free Documentation License")
  N_("url_link_for_Creative Commons: Attribution Non-commercial No Derivatives (by-nc-nd)")
  N_("url_link_for_Creative Commons: Attribution Non-commercial Share Alike (by-nc-sa)")
  N_("url_link_for_Creative Commons: Attribution Non-commercial (by-nc)")
  N_("url_link_for_Creative Commons: Attribution No Derivatives (by-nd)")
  N_("url_link_for_Creative Commons: Attribution Share Alike (by-sa)")
  N_("url_link_for_Creative Commons: Attribution (by)")


  # referenced by: project validation
  N_("Public Domain")
  N_("This project contains no code")
  N_("Other licenses")
  LICENSES = Hash[ * LICENSE_DATA.flatten ].freeze
  LICENSE_DISPLAY_KEYS = LICENSE_DATA.map(&:first).map(&:to_i).freeze
  def self.license_to_s(i_or_s)
    _(LICENSES[i_or_s.to_i])
  end
  # ",5,1," => [ [1, "xx"], [5, "oo"] ]
  def self.licenses_to_s(licenses_with_delimiter)
    rtn = []
    choosen = (licenses_with_delimiter || "").split(",").grep(/./).map(&:to_i)
    Project::LICENSE_DISPLAY_KEYS.each do |i|
      if choosen.include?(i)
        rtn << [i, license_to_s(i)]
      end
    end
    rtn
  end
  def licenses_to_s
    Project.licenses_to_s(self.license)
  end




  # [ [1, "CC"],
  #   [2, "GFDL"] ]
  # having mutiple spaces is ok
  CONTENT_LICENSE_DATA = <<"EOEO".split("\n").map {|x| (i, s) = x.split(" ", 2); [ i.to_i, s ] }
0 Project contains only code
-3 Same license as code
-2 Public Domain
1 GNU Free Documentation License
2 Creative Commons: Attribution Non-commercial No Derivatives (by-nc-nd)
3 Creative Commons: Attribution Non-commercial Share Alike (by-nc-sa)
4 Creative Commons: Attribution Non-commercial (by-nc)
5 Creative Commons: Attribution No Derivatives (by-nd)
6 Creative Commons: Attribution Share Alike (by-sa)
7 Creative Commons: Attribution (by)
-1 Other licenses
EOEO
  # referenced by: project validation / _form
  N_("Public Domain")
  N_("Same license as code")
  N_("Project contains only code")
  N_("Other licenses")
  CONTENT_LICENSES = Hash[ * CONTENT_LICENSE_DATA.flatten ].freeze
  CONTENT_LICENSE_DISPLAY_KEYS = CONTENT_LICENSE_DATA.map(&:first).map(&:to_i).freeze
  def self.content_license_to_s(i_or_s)
    _(CONTENT_LICENSES[i_or_s.to_i])
  end
  # ",5,1," => [ [1, "xx"], [5, "oo"] ]
  def self.content_licenses_to_s(licenses_with_delimiter)
    rtn = []
    choosen = (licenses_with_delimiter || "").split(",").grep(/./).map(&:to_i)
    Project::CONTENT_LICENSE_DISPLAY_KEYS.each do |i|
      if choosen.include?(i)
        rtn << [i, content_license_to_s(i)]
      end
    end
    rtn
  end
  def content_licenses_to_s
    Project.content_licenses_to_s(self.contentlicense)
  end


  # see also: OpenFoundry.pm

  # single selection
  VCS = { :NONE => 0, :CVS => 1, :SUBVERSION => 2, :SUBVERSION_CLOSE => 3, :REMOTE => -1 }.freeze
  # i18n at vcs_to_s

  # mutiple selection + other (string,string,...)
  PLATFORMS = [ "Windows", "FreeBSD", "Linux", "Java Environment", ".NET Environment", "MacOSX", "MacOS Classic" ].freeze

  # mutiple selection + other (string,string,...)
  PROGRAMMING_LANGUAGES = [ "Assembly", "C", "C++", "Java", "Perl", "PHP", "Python", "Ruby" ].freeze

  # this field will only contains old values migrated from RT
  # INTENDED_AUDIENCE = [ "General Use", "Programmer", "System Administrator", "Education", "Researcher" ]
  
  #
  # important INTERNAL status
  #
  STATUS = { :APPLYING => 0, :REJECTED => 1, :READY => 2, :SUSPENDED => 3, :PENDING => 4 }.freeze

	# find the ready projects
	named_scope :in_used, :conditions => { :status => Project::STATUS[ :READY ] } 

  #for releases ftp upload and web download...
  PROJECT_UPLOAD_PATH = OPENFOUNDRY_PROJECT_UPLOAD_PATH.freeze
  PROJECT_DOWNLOAD_PATH = "#{RAILS_ROOT}/public/download".freeze  

  # name validation
  NAME_REGEX = /^[a-z][0-9a-z-]{2,13}[0-9a-z]$/ # lengh = 15
  
  def self.status_to_s(int_status)
    _(STATUS.index(int_status).to_s)
  end
  def self.maturity_to_s(int_maturity)
    _(MATURITY.index(int_maturity).to_s)
  end
  def maturity_to_s
    Project.maturity_to_s(maturity)
  end
  # Project.vcs_to_s(1)    or
  # Project.vcs_to_s(:CVS)
  def self.vcs_to_s(vcs) # int or symbol
    i = (Symbol === vcs) ? VCS[vcs] : vcs.to_i
    case i
    when VCS[:CVS]
      _("CVS")
    when VCS[:SUBVERSION]
      _("Subversion")
    when VCS[:SUBVERSION_CLOSE]
      _("Subversion: members only")
    when VCS[:REMOTE]
      _("This project uses a version control system at other site.")
    when VCS[:NONE]
      _("This project does not use any version control system.")
    else
      _("System Error. Please contact the site administrator.")
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
                                                :index => :yes },                                                         
															:cattag_name => {:store => :yes,
																					:index => :yes }					
                            },
                 :single_index =>true
                 },{ :analyzer => GENERIC_ANALYZER, :default_field => DEFAULT_FIELD})
  def cattag_name;cattag.name;end
  		

  def should_be_indexed?
    self.status == Project::STATUS[:READY]
  end
  def ferret_enabled?(is_bulk_index = false)
    should_be_indexed? && #super(is_bulk_index) # TODO: super will cause recursive call..
      (@ferret_disabled.nil? && (is_bulk_index || self.class.ferret_enabled?))
  end
  def destroy_ferret_index_when_not_ready
    ferret_destroy if not should_be_indexed?
  end
  after_save :destroy_ferret_index_when_not_ready
    
  #add tags
  acts_as_taggable
  
  #model relationships
  has_many :releases
  has_many :ready_releases, :class_name => 'Release', 
	   :conditions => { :status => Release::STATUS[ :RELEASED ] },
	   :order => 'updated_at DESC'

  # field validations...
  # see also: http://rt.openfoundry.org/Edit/Queues/CustomField/?Queue=4
  #
  # Don't forget to modify "db/migrate/001_create_tables.rb"
  # 
  # see: /activerecord-2.0.2/lib/active_record/validations.rb
  validates_format_of :name, :with => NAME_REGEX, :message => _('Format|Project Name')
    validates_exclusion_of :name, :in => %w( admin www svn cvs list lists sympa kwiki wiki ftp ), :message => _("This name is reserved by the system.")
  validates_length_of :summary, :within => 3 .. 255
  # rationale: only for backward compatibility
  validates_length_of :description, :within => 3 .. 4000
  validates_length_of :contactinfo, :maximum => 255
  validates_inclusion_of :maturity, :in => MATURITY.values
  validates_length_of :license, :maximum => 50, :message => _('You have choosen too many licenses.')
    validates_format_of :license, :with => /,(-?\d+)*,/
  validates_length_of :contentlicense, :maximum => 50, :message => _('You have choosen too many content licenses.')
    validates_format_of :contentlicense, :with => /,(-?\d+)*,/
  validates_length_of :licensingdescription, :maximum => 1000
  validates_length_of :platform, :maximum => 100
  validates_length_of :programminglanguage, :maximum => 100
  # intendedaudience: only for backward compatibility
  validates_length_of :redirecturl, :maximum => 255 # TODO: should be a valid url! (and no loop)
  validates_inclusion_of :vcs, :in => VCS.values
  validates_length_of :vcsdescription, :maximum => 100

  # Project.new(:name => 'openfoundry').valid?
  ### also invoked by approve()
  ##def validate_on_create
  ##  if Project.exists?(Project.in_used_projects(['name = ?', name]))
  ##    errors.add(:name, _("'#{name}' has already been taken"))
  ##  end
  ##end

  def validate
    if status != Project::STATUS[:REJECTED]
      cond = ["name = ? and #{Project.approved_projects}", name]
      cond = [cond[0] + "and id <> ?", cond[1], id] if not new_record? # for "approve"
      errors.add(:name, _("'#{name}' has already been taken")) if Project.exists?(cond)
    end

    ls = "#{license}".split(",").grep(/./).map(&:to_i)
    if ls.length == 0
      errors.add(:license, _("Please choose at least one code license."))
    end
    if ls.include?(0) and ls != [0] 
      errors.add(:license, _("If this project contains no code, then you may not choose any other license."))
    end

    cls = "#{contentlicense}".split(",").grep(/./).map(&:to_i)
    if cls.length == 0
      errors.add(:contentlicense, _("Please choose at least one content license."))
    end
    if cls.include?(0) and cls != [0] 
      errors.add(:contentlicense, _("If this project contains only code, then you may not choose any other content license."))
    end
    if cls.include?(-3) and cls != [-3] 
      errors.add(:contentlicense, _("If the content license is the same with the code license, then you may not choose any other content license."))
    end

    if cls == [-3] and ls == [0] 
      errors.add(:contentlicense, _("You have to choose a code license.")) # TODO: better wording
    end

    if (ls.include?(-1) or cls.include?(-1)) and "#{licensingdescription}".strip.blank?
      errors.add(:licensingdescription, _("You have to fill in the \"Licensing Description\" if you choosed \"Other licenses\"."))
    end

    if "#{platform}".split(",").grep(/./).empty?
      errors.add(:platform, _("Please choose at least one platform."))
    end

    if "#{programminglanguage}".split(",").grep(/./).empty?
      errors.add(:programminglanguage, _("Please choose at least one programming language."))
    end
  end
  

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
    data[:icon] = Image::IMAGE_DEFAULT_PROJECT_ICON

    returning Project.create(data) do |project|
      if project.errors.empty?
        #ProjectNotify.deliver_applied_site_admin(project)
        ProjectNotify.deliver_project_reviewer(project)
      end
    end
  end

  # reason: string
  def approve(reason, replymessage)
    raise "current status is wrong: #{self.status}" if not [Project::STATUS[:APPLYING], Project::STATUS[:PENDING], Project::STATUS[:REJECTED]].include?(self.status)

    reason = replymessage + "\n" + reason
    if not update_attributes(:status => Project::STATUS[:READY], :statusreason => reason)
      return false
    end

    # add default roles: Admin/Member
    ['Admin', 'Member'].each do |role_name|
      self.roles.new do |r|
        r.name = role_name 
        r.authorizable_type = 'Project'
        Role.set_default_privileges_for r
      end.save
    end

    # TODO: transaction / efficiency / constant
    set_role("Admin", User.find(self.creator))
    # TODO: hook / listener / callback / ...
    ApplicationController::send_msg(TYPES[:project], ACTIONS[:create], {:id => self.id, :name => self.name, :summary => self.summary})
    # send admin function creation msg
    Function.find(:all).each do |f|
      ApplicationController::send_msg(:function,:create,
                        {:function_name => f.name, 
                          :user_id => self.creator,
                          :project_id => self.id 
                        })
    end
    Release::build_path(self.name, self.id)
    ProjectNotify.deliver_approved(self, replymessage)
  end
  # reason: string
  def reject(reason, replymessage)
    raise "current status is wrong: #{self.status}" if not [Project::STATUS[:APPLYING], Project::STATUS[:PENDING]].include?(self.status)
    self.status = Project::STATUS[:REJECTED]
    self.statusreason = replymessage + "\n" + reason
    if save!
      ProjectNotify.deliver_rejected(self, replymessage)
    end
  end
  # reason: string
  def suspend(reason)
    raise "current status is wrong: #{self.status}" if self.status != Project::STATUS[:READY]
    self.status = Project::STATUS[:SUSPENDED]
    self.statusreason = reason
    save!
    # TODO: notify by email
  end
  # reason: string
  def resume(reason)
    raise "current status is wrong: #{self.status}" if self.status != Project::STATUS[:SUSPENDED]
    self.status = Project::STATUS[:READY]
    self.statusreason = reason
    save!
    # TODO: notify by email
  end
  # reason: string
  def pending(reason, replymessage)
    raise "current status is wrong: #{self.status}" if not [Project::STATUS[:APPLYING], Project::STATUS[:REJECTED]].include?(self.status) 
    self.status = Project::STATUS[:PENDING]
    self.statusreason = replymessage + "\n" + reason
    save!
    if save!
      ProjectNotify.deliver_pending(self, replymessage)
    end
  end

  # Project.find(:first, :conditions => ["name = ? and #{Project.in_used_projects}", 'openfoundry'])
  #                                     ["name = ? and (status = 2)", "openfoundry"]
  # Project.find(:first, :conditions => "name = 'openfoundry' and #{Project.in_used_projects}")
  #                                     "name = 'openfoundry' and (status = 2)"
  # Project.find(:first, :conditions => Project.in_used_projects)
  #                                     "(status = 2)"
  # Project.in_used_projects(:alias => "projects")
  #                                     "(projects.status = 2)"
  def self.in_used_projects(options = {})
    a = options[:alias] ? options[:alias] + "." : ""
    "(#{a}status = #{Project::STATUS[:READY]})"
  end
  def self.approved_projects(options = {})
    a = options[:alias] ? options[:alias] + "." : ""
    "(#{a}status = #{Project::STATUS[:READY]} or #{a}status = #{Project::STATUS[:SUSPENDED]})"
  end
  def self.pending_projects(options = {})
    a = options[:alias] ? options[:alias] + "." : ""
    "(#{a}status = #{Project::STATUS[:PENDING]})"
  end

  def self.new_projects
    Project.find(:all, :conditions => Project.in_used_projects(), :order => "created_at desc", :limit => 5)
  end

  def self.assign_default_role
    %w(Admin Member).each do |name|
      Project.find(:all, :conditions => Project.in_used_projects).map do |p|
        r=nil
        unless r = Role.find_by_name(name, :conditions => "authorizable_id = #{p.id}")
          r = Role.create({:name => name, 
                          :authorizable_id => p.id, 
                          :authorizable_type => 'Project'})
        end
        Role.set_default_privileges_for r
        r.id
      end
    end
  end

  #
  # NSC
  #
  def is_nsc_project
    is_nsc_project = self.tag_list.names.any? {|t| t =~ /^NSC/}
  end
  def is_nsc_reviewer(user_login)
    l = "#{self.name} #{user_login}\n" # DOS ?
    File.open(NSC_REVIEWERS_FILE).each do |line|
      return true if line == l
    end
    return false
  end
  def self.project_names_of_the_reviewer(user_login)
    rtn = []
    return rtn unless "#{user_login}".length > 0
    r = /^(.*)\s+#{user_login}$/
    File.open(NSC_REVIEWERS_FILE).each do |line|
      rtn << $1 if line =~ r
    end
    return rtn.sort
  end
  def nsc_role(user_obj)
    if user_obj.has_role?('Admin', self)
      "PI"
    elsif is_nsc_reviewer(user_obj.login) # has_role?('nsc_reviewer', @project)
      "REVIEWER"
    elsif user_obj.login == NSC_ADMIN_ACCOUNT
      "ADMIN"
    else
      nil
    end
  end
  def nsc_codes
    tag_list.names.grep(/^NSC\d/).sort
  end
  def nsccode=(code_array)
    self.tag_list = []
    self.tag_list.add(* code_array.map(&:strip).map(&:upcase).grep(/^NSC/))
  end

  def valid_users_of_role(role_name_string)
    roles.find_by_name(role_name_string, :select => "id").users.valid_users
  end
  
  def dump(options = {})
    file_type = options[:type]||:csv
    columns = self.class.content_columns.map{|c|c.name}
    columns -= ['icon', 'vcs', 'vcsdescription', 'status', 
                'created_at', 'updated_at', 'updated_by', "statusreason"]
    columns.insert(0,'id')
    columns.concat(['creator_email','member_emails'])
    creator = User.valid_users.find_by_id(self.send('creator'))
    member_emails = roles.map{|r|r.users.map{|u|"#{u.login}:#{u.email}"}}.flatten.join('|')
    case(file_type)
    when :csv :
      columns.map{|c|"\"#{
      if(c=='creator')
        v = "#{creator.login}" 
      elsif(c=='creator_email')  
        v = "#{creator.email}" 
      elsif (c == 'member_emails')
        v = member_emails 
      else
        v = (self.send(c)||'');
      end 
      if(v.respond_to?(:gsub));
        v.gsub('"',"'").gsub("\n",'').gsub("\r",'').gsub(',',"，");
      else v;
      end
    }\""}.join(options[:split]||',') 
    end
  end
end
