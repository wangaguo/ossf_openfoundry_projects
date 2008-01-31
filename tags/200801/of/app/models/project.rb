class Project < ActiveRecord::Base
  has_many :roles, :foreign_key => "authorizable_id", :conditions => "authorizable_type='Project'"
  LICENSES = [ "GPL", "LGPL", "BSD" ].freeze
  CONTENT_LICENSES = [ "CC", "KK" ].freeze
  #VCS = [ "Subversion", "CVS" ].freeze
  VCS = [ "svn", "cvs" ].freeze
  PLATFORMS = [ "Windows", "FreeBSD", "Linux", "Java Environment" ].freeze
  PROGRAMMING_LANGUAGES = [ "C", "Java", "Perl", "Ruby" ].freeze
  INTENDED_AUDIENCE = [ "General Use", "Programmer", "System Administrator", "Education", "Researcher" ]
  STATUS = { :APPLYING => 0, :REJECTED => 1, :READY => 2, :SUSPENDED => 3 }
  #for releases ftp upload and web download...
  PROJECT_UPLOAD_PATH = "/usr/upload".freeze
  PROJECT_DOWNLOAD_PATH = "#{RAILS_ROOT}/public/download".freeze  
  
  def self.status_to_s(int_status)
    STATUS.invert()[int_status]
  end
  #validates_inclusion_of :license, :in => LICENSES

  #support Project-User relationship
  acts_as_authorizable

  #add fulltext indexed SEARCH
  acts_as_ferret 

  #add tags
  acts_as_taggable
  
  #model relationships
  has_many :release
  
  #field validations...
  #validates_format_of :unixname, :with => /^[a-zA-Z][0-9a-zA-Z]{2,15}$/
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
    Release::build_path(self.unixname)
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

  # Project.find(:first, :conditions => Project.in_used_projects(['unixname = ?', 'openfoundry']))
  # Project.find(:first, :conditions => Project.in_used_projects("unixname = 'openfoundry'"))
  # Project.find(:first, :conditions => Project.in_used_projects())
  # Project.exists?(Project.in_used_projects(['unixname = ?', unixname]))
  def self.in_used_projects(condition = 'true')
    if condition.is_a?(String)
      "(#{condition}) and (status = #{Project::STATUS[:READY]} or status = #{Project::STATUS[:SUSPENDED]})"
    elsif condition.is_a?(Array)
      [ in_used_projects(condition[0]), condition[1 .. -1] ]
    else
      raise "wrong usage!"
    end
  end

  # Project.new(:unixname => 'openfoundry').valid?
  def validate
    # read http://dev.rubyonrails.org/changeset/5192 
    # and active_record/calculations.rb
    #if Project.count(:conditions => Project.in_used_projects(['unixname = ?', unixname])) > 0
    if Project.exists?(Project.in_used_projects(['unixname = ?', unixname]))
      errors.add(:unixname, "'#{unixname}' has already been used")
    end
  end
end
