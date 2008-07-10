require 'of'
class SiteAdmin::SiteAdminController < SiteAdmin
  def index
  end
  def resend
    include OpenFoundry::Message
   
    User.find(:all, :conditions => User.verified_users()).each do |u|
      send_msg(TYPES[:user],ACTIONS[:create],{'id' => u.id, 'name' => u.login})
    end
  
    Project.find(:all, :conditions => Project.in_used_projects()).each do |p|
      send_msg(TYPES[:project], ACTIONS[:create], {'id' => p.id, 'name' => p.summary, 'summary' => p.description}) 
    end
    
    redirect_to :action => :index
  end
end
