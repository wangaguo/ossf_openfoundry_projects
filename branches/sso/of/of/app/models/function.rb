class Function < ActiveRecord::Base
  has_and_belongs_to_many :roles, :join_table => 'roles_functions'

  # Function.functions(:authorizable_id => 1018, :user_id => 1000025)
  # =>  ["project_info", "project_member", ... "vcs_commit", "ftp_access"]
  def self.functions(options = { :authorizable_type => '', :authorizable_id => '', :user_id => ''})
    at = options[:authorizable_type] || 'Project'
    ai = options[:authorizable_id]
    ui = options[:user_id] || 0
    raise "bad parameter! ui =#{ui}" if at !~ /^\w+$/ or (not Fixnum === ai) or (not Fixnum === ui)

    #if user is the admin of this project, return all functions
    if Role.count_by_sql(
      "select U.id from roles R, roles_users RU, users U, projects P
        where U.id = RU.user_id and R.id = RU.role_id and R.name = 'Admin' and
              R.authorizable_id = '#{ai}' and
              R.authorizable_type = 'Project' and
              R.authorizable_id  = P.id and
              #{Project.in_used_projects(:alias => 'P')} and
              U.id = '#{ui}'
        ") > 0
      sql = "select F.name from functions F"
    else
      sql = "select F.name from functions F, 
           roles_functions RF, roles R,
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
        where U.id = RU.user_id and R.id = RU.role_id and R.name = 'Admin' and
              R.authorizable_id = '#{authorizable_id}' and 
              R.authorizable_type = 'Project' and 
              R.authorizable_id  = P.id and 
              #{Project.in_used_projects(:alias => 'P')} and 
              U.login = '#{user.login}' 
        ") > 0
    
    #else check every permission carefully!
    if(0 < Function.count_by_sql("" +
        "select count(*) from roles, roles_users, users, roles_functions, functions, projects " +
        "where roles_users.user_id = users.id and roles_users.role_id = roles.id and " +
        "roles_functions.role_id = roles.id and roles_functions.function_id = functions.id and " +
        "roles.authorizable_type = '#{authorizable_type}' and " + 
        "roles.authorizable_id = '#{authorizable_id}' and " +
        "roles.authorizable_id = projects.id and " +
        "#{Project.in_used_projects(:alias => 'projects')} and " +
        "users.login = '#{user.login}' and " + 
        "functions.name = '#{function_name}'"))
      return true
    else
      return false;
    end
  end
  N_("Permission|Modify Project Information")
  N_("Permission|Add/Remove Project Members")
  N_("Permission|Edit Role Permissions")
  N_("Permission|Manage Releases")
  N_("Permission|Manage News")
  N_("Permission|Manage Help Wanted")
  N_("Permission|Manage Citations")
  N_("Permission|Manage References")
  N_("Permission|Manage Kwiki Pages")
  N_("Permission|Set As Tracker Admin")
  N_("Permission|Set As Tracker CC")
  N_("Permission|Manage Sympa Mailing Lists")
  N_("Permission|Commit Changes")
  N_("Permission|Ftp Access")
  N_("Permission|Manager Download Surveys")

end
