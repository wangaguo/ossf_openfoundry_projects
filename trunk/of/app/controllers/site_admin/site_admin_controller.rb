class SiteAdmin::SiteAdminController < SiteAdmin
  def index
  end
  def aaf_rebuild
    User.rebuild_index(User,Project,Release,News,Fileentity)
    redirect_to :action => :index
  end
  def resend
    #User.find(:all, :conditions => User.verified_users()).each do |u|
    #  ApplicationController::send_msg(TYPES[:user],ACTIONS[:create],{'id' => u.id, 'name' => u.login})
    #end
  
    #Project.find(:all, :conditions => Project.in_used_projects()).each do |p|
    #  ApplicationController::send_msg(TYPES[:project], ACTIONS[:create], {'id' => p.id, 'name' => p.summary, 'summary' => p.description}) 
    #end
    
    ActiveRecord::Base.connection.select_rows(
    "select distinct U.id, P.id, F.name from users U, roles_users RU, roles_functions RF, functions F, roles R, projects P where
             U.id = RU.user_id and 
             ( ( RU.role_id = RF.role_id and RF.function_id = F.id) or
             ( R.name = 'Admin' ) ) and
             RU.role_id = R.id and R.authorizable_type = 'Project' and
             R.authorizable_id = P.id and 
             #{User.verified_users(:alias => 'U')} and 
             #{Project.in_used_projects(:alias => 'P')} order by U.id
           ").each do |u, p, f|
             ApplicationController::send_msg(TYPES[:function],ACTIONS[:create],{'user_id' => u, 'project_id' => p, 'function_name' => f})
    end
    
    redirect_to :action => :index
  end
end
