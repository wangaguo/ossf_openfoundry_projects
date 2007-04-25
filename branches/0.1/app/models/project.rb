class Project < ActiveRecord::Base
  has_many :project_users
  has_many :users, :through => :project_users
  has_many :admins,
    :through => :project_users,
    :source => :user,
    :conditions => ["project_users.role = 'Admin'"]
  has_many :members,
    :through => :project_users,
    :source => :user,
    :conditions => ["project_users.role = 'Member'"]

  LICENSES = [ "GPL", "LGPL", "BSD" ].freeze
  validates_inclusion_of :license, :in => LICENSES
end
