class SiteAdmin::SiteAdminController < SiteAdmin
  layout 'application'

  def switch_user_search #search for user, use in 'Project Add Member'
    name = params['username']
    limit = params['limit'] || 21
    users = unless name.blank?
      User.find_by_sql(
        ["select id,icon,login,realname,email from users where 
                          #{User.verified_users} and login like  ? limit ?","%#{name}%" ,limit])
    else
      []
    end
    render(:partial => 'search_hit_member',
      :locals => {:users => users},
      :layout => false)
  end
   
  def switch_user
    session['effective_user'] = User.find_by_id(params[:id])
    redirect_to '/user/home'
  end

  def index
    cookies['HeaderOnOff'] = 'OFF'
  end
  def gettext_cache_switch
    GetText.cached = !GetText.cached? 
    render :text => "switch to #{GetText.cached?} @ #{Time.now}"
  end
  def aaf_rebuild
    User.rebuild_index(User,Project,Release,News,Fileentity)
    redirect_to :action => :index
  end

  def rescue_user
    User.find(:all, :conditions => User.verified_users() + " and id > 200000").each do |u|
      ApplicationController::send_msg(TYPES[:user],ACTIONS[:create],{'id' => u.id, 'name' => u.login})
    end
  end
  def rescue_project
    Project.find(:all, :conditions => Project.in_used_projects() + " and id >= 964").each do |p|
      ApplicationController::send_msg(TYPES[:project], ACTIONS[:create], {'id' => p.id, 'name' => p.summary, 'summary' => p.description}) 
    end
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
