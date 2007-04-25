class ProjectUser < ActiveRecord::Base
  belongs_to :project
  belongs_to :user

  ROLES = [ "Admin", "Member" ].freeze
  validates_inclusion_of :role, :in => ROLES

  def self.set_role(project_id, user_id, role)
    pu = find_or_create_by_project_id_and_user_id(project_id, user_id)
    pu.role = role
    pu.save
  end

  # TODO: take a better method name ...
  def self.delete_all_in_user_id(project_id, user_ids)
    q = ['?'] * user_ids.length * ','
    delete_all ["project_id = ? and user_id in (#{q})", project_id, *user_ids]
  end
end
