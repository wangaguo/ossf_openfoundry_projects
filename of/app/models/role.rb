# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_and_belongs_to_many :functions, :join_table => 'roles_functions'
  belongs_to :authorizable, :polymorphic => true

  def editable?
    self.name.downcase != 'admin'
  end
  
  def deletable?
    self.name.downcase != 'admin' and
      self.name.downcase != 'member'
  end
  
  def self.set_default_privileges_for(role)
    case role.name.downcase
    when 'admin'
      role.functions << Function.find(:all)
    when 'member'
      role.functions << Function.find(13) #vcs_commit
      role.functions << Function.find(9) #kwiki_manage
      role.functions << Function.find(11) #rt_member
    end
  end
end
