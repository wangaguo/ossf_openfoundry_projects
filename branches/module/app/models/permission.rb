class Permission < ActiveRecord::Base
  has_and_belongs_to_many :roles, :join_table => 'roles_permissions'

  # Permission.permissions(:authorizable_id => 1018, :user_id => 1000025)
  # =>  ["project_info", "project_member", ... "vcs_commit", "ftp_access"]
  def self.permissions(options = { :authorizable_type => '', :authorizable_id => '', :user_id => ''})
    at = options[:authorizable_type] || 'Project'
    ai = options[:authorizable_id]
    ui = options[:user_id] || 0
    raise "bad parameter! ui =#{ui}" if at !~ /^\w+$/ or (not Fixnum === ai) or (not Fixnum === ui)

    #if user is the admin of this project, return all permissions
    if Role.count_by_sql(
      "select U.id from roles R, roles_users RU, users U, projects P
        where U.id = RU.user_id and R.id = RU.role_id and R.name = 'Admin' and
              R.authorizable_id = '#{ai}' and
              R.authorizable_type = 'Project' and
              R.authorizable_id  = P.id and
              #{Project.in_used_projects(:alias => 'P')} and
              U.id = '#{ui}' and
              #{User.verified_users(:alias => 'U')}
        ") > 0
      sql = "select F.name from permissions F"
    else
      sql = "select F.name from permissions F, 
           roles_permissions RF, roles R,
           roles_users RU, users U
           where
           RF.function_id = F.id and RF.role_id = R.id and
           RU.role_id = R.id and RU.user_id = U.id and
           R.authorizable_type = '%s' and R.authorizable_id = %d and
           U.id = %d 
          " % [at, ai, ui]
    end
    #puts "sql: #{sql}"
    ActiveRecord::Base.connection.select_values(sql)
  end
  
  def self.function_permit(user, function_name, authorizable_id, authorizable_type)
    #if site admin, allow it anyway
    return true if user.has_role? "site_admin"
    #if the permission is allow_all, allow it whoever 
    return true if function_name.to_s == 'allow_all'

    #if user is the admin of this project, allow it anyway
    return true if Role.count_by_sql(
      "select U.id from roles R, roles_users RU, users U, projects P  
        where U.id = RU.user_id and R.id = RU.role_id and R.name IN ('Admin') and
              R.authorizable_id = '#{authorizable_id}' and 
              R.authorizable_type = 'Project' and 
              R.authorizable_id  = P.id and 
              #{Project.in_used_projects(:alias => 'P')} and 
              U.login = '#{user.login}' and 
              #{User.verified_users(:alias => 'U')}
        ") > 0
    
    #else check every permission carefully!
    if(0 < Permission.count_by_sql("" +
        "select count(*) from roles, roles_users, users, roles_permissions, permissions, projects " +
        "where roles_users.user_id = users.id and roles_users.role_id = roles.id and " +
        "roles_permissions.role_id = roles.id and roles_permissions.function_id = permissions.id and " +
        "roles.authorizable_type = '#{authorizable_type}' and " + 
        "roles.authorizable_id = '#{authorizable_id}' and " +
        "roles.authorizable_id = projects.id and " +
        "#{Project.in_used_projects(:alias => 'projects')} and " +
        "users.login = '#{user.login}' and " + 
        "#{User.verified_users(:alias => 'users')} and " +
        "permissions.name = '#{function_name}'"))
      return true
    else
      return false;
    end
  end
end
