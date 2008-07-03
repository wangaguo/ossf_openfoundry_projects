class Function < ActiveRecord::Base
  has_and_belongs_to_many :roles, :join_table => 'roles_functions'
  
  def self.function_permit(function_name, authorizable_id, authorizable_type)
    #if site admin, allow it anyway
    return true if current_user.has_role? "site_admin"
    #if the permission is allow_all, allow it whoever 
    return true if function_name.to_s == 'allow_all'

    #if user the the admin of this project, allow it anyway
    return true if Role.count_by_sql("select U.id from roles R, roles_users RU, users U 
        where U.id = RU.user_id and R.id = RU.role_id and R.name = 'Admin' and
              R.authorizable_id = '#{authorizable_id}' and 
              R.authorizable_type = 'Project' and
              U.login = '#{current_user.login}'                    
        ") > 0
    
    #else check every permission carefully!
    if(0 < Function.count_by_sql("" +
        "select count(*) from roles, roles_users, users, roles_functions, functions " +
        "where roles_users.user_id = users.id and roles_users.role_id = roles.id and " +
        "roles_functions.role_id = roles.id and roles_functions.function_id = functions.id and " +
        "roles.authorizable_type = '#{authorizable_type}' and " + 
        "roles.authorizable_id = '#{authorizable_id}' and " +
        "users.login = '#{current_user.login}' and " + 
        "functions.name = '#{function_name}'"))
      return true
    else
      return false;
    end
  end
end
