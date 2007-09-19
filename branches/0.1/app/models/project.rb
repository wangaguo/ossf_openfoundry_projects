class Project < ActiveRecord::Base
  LICENSES = [ "GPL", "LGPL", "BSD" ].freeze
  CONTENT_LICENSES = [ "CC", "KK" ].freeze
  PLATFORMS = [ "Windows", "FreeBSD", "Linux", "Java Environment" ].freeze
  PROGRAMMING_LANGUAGES = [ "C", "Java", "Perl", "Ruby" ].freeze
  INTENDED_AUDIENCE = [ "General Use", "Programmer", "System Administrator", "Education", "Researcher" ].freeze
  #validates_inclusion_of :license, :in => LICENSES

  acts_as_authorizable
  has_many :roles, :finder_sql => <<-END
		SELECT r.* 
		FROM roles AS r
		WHERE authorizable_type = "Project"
                AND authorizable_id = "#{id}"
          	ORDER BY r.name
		END
  #add fulltext indexed SEARCH
  acts_as_ferret 

  #add tags
  acts_as_taggable

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
