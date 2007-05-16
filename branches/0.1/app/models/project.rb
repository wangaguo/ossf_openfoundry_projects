class Project < ActiveRecord::Base
  LICENSES = [ "GPL", "LGPL", "BSD" ].freeze
  CONTENT_LICENSES = [ "CC", "KK" ].freeze
  PLATFORMS = [ "Windows", "FreeBSD", "Linux", "Java Environment" ].freeze
  PROGRAMMING_LANGUAGES = [ "C", "Java", "Perl", "Ruby" ].freeze
  INTENDED_AUDIENCE = [ "General Use", "Programmer", "System Administrator", "Education", "Researcher" ]
  #validates_inclusion_of :license, :in => LICENSES


  acts_as_authorizable

  def admins
    has_admins
  end
  def members
    has_members
  end
  def set_role(role, user) # user obj, role string
    raise ArgumentError, "user is not defined" unless User === user
    Role.validates_role(role)
    user.has_role role, self 
  end
end
