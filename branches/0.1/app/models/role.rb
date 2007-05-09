# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  belongs_to :authorizable, :polymorphic => true

  ROLES = [ "Admin", "Member" ].freeze
  validates_inclusion_of :name, :in => ROLES

  def self.valid_role? (role)
    ROLES.include? role
  end 
  def self.validates_role(role) # role string
    raise StandardError "not a valid role: #{role}" unless valid_role?(role)
  end 
end
