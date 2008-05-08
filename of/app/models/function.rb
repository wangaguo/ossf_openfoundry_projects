class Function < ActiveRecord::Base
  has_and_belongs_to_many :roles, :join_table => 'roles_functions'
  
  def self.function_permit(project_name, function_name)
    if(0 < Function.count_by_sql("" +
        "select count(*) from roles, roles_users, users, projects, roles_functions, functions " +
        "where roles_users.user_id = users.id and roles_users.role_id = roles.id and " +
        "roles_functions.role_id = roles.id and roles_functions.function_id = functions.id and " +
        "roles.authorizable_type = 'Project' and roles.authorizable_id = projects.id and " +
        "users.login = '" + current_user.login + "' and projects.name = '" + project_name +"' and functions.name = '" + function_name +"'"))
      return true
    else
      return false;
    end
  end
end
