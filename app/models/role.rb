# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_and_belongs_to_many :functions, :join_table => 'roles_functions'
  belongs_to :authorizable, :polymorphic => true

  def validate
    unless new_record?
      if users.length==0 and name.downcase=='admin'
        errors.add :users, _("Group \"Admin\" CAN NOT be EMPTY.")
        return false
      end
    end
  end

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

  def valid_users
    users.valid_users
  end

  #for ajax i18n
  N_('This will remove User from this Group, are you sure?')
  N_('This will add User to this Group, are you sure?')
end
