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
    session[:effective_user] = User.find_by_id(params[:id])
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
    User.rebuild_index(Project,Release,News,Fileentity)
    redirect_to :action => :index
  end

  def rescue_user
    User.find(:all, :conditions => User.verified_users() + " and id = 201159").each do |u|
      ApplicationController::send_msg(TYPES[:user],ACTIONS[:create],{:id => u.id, :name => u.login, :email => u.email })
    end
  end

  def rescue_user_update
    User.find(:all, :conditions => User.verified_users() + " and id >= 200000").each do |u|
      ApplicationController::send_msg(TYPES[:user],ACTIONS[:update],{:id => u.id, :name => u.login, :email => u.email })
    end
  end

  def rescue_project
    Project.find(:all, :conditions => Project.in_used_projects() + " and id >= 996").each do |p|
      ApplicationController::send_msg(TYPES[:project], ACTIONS[:create], {:id => p.id, :name => p.name, :summary => p.summary}) 
    end
  end

  def resend
    
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
             ApplicationController::send_msg(TYPES[:function],ACTIONS[:create],{:user_id => u, :project_id => p, :function_name => f})
    end
    
    redirect_to :action => :index
  end

  def new_site_mail
    filter_file = File.join(Rails.configuration.root_path, 'config', 'site_mail_filter.txt')
    if request.post? then
      @mail = Hashit.new(params[:mail])
      bcc_max = OPENFOUNDRY_SITEMAIL_BATCH_MAX 
      bcc_j = 0
      bcc_i = 0
      bcc = []

      case @mail.type 
      when "to"
        bcc[0] = @mail.to 
      when "all_valid_users", "all_valid_users_and_filter"
        if @mail.type == "all_valid_users" then
          users = User.valid_users
        else
          @mail.filter = "'" + @mail.filter.gsub(/[^a-zA-Z0-9,_]/, '').gsub(/,/, "','") + "'"
          f = File.new(filter_file, "w")
          f.write(@mail.filter)
          f.close
          users = User.find(:all, :conditions => "#{User::verified_users} and login not in(#{@mail.filter})")
        end
        users.each do |user|
          if bcc[bcc_i].nil? then bcc[bcc_i] = "" else bcc[bcc_i] += ", " end
          bcc[bcc_i] += "#{user.login} <#{user.email}>"
          if (bcc_j+=1) == bcc_max then
            bcc_j=0
            bcc_i+=1
          end
        end
      end

      mail = UserNotify.create_site_mail(@mail.subject, @mail.message)
      mail_check = UserNotify.create_site_mail(@mail.subject, "")
      bcc_i = 0

      bcc.each do |bc|
        run_later do
          bcc_i+=1
          mail.bcc = bc
          UserNotify.deliver(mail)

          mail_check.bcc = OPENFOUNDRY_SITE_ADMIN_EMAIL 
          mail_check.body = "users=#{users.length if !users.nil?}<br/>bcc_max=#{bcc_max}<br/>bcc_batch=#{bcc.length}<br/>bcc_i=#{bcc_i}"
          UserNotify.deliver(mail_check)
        end
      end

      flash.now[:notice] = _('Message sent.')
    else
      m = {:type => "to", :to => "", :filter => "" , :subject => "[OpenFoundry]", :message => "Please input HTML content."}
      @mail = Hashit.new(m)

      if File.exist?(filter_file) then
        File.readlines(filter_file).each do |line|
          @mail.filter = line
          break
        end
      end
    end
  end

  def run_code
    load OPENFOUNDRY_SITE_ADMIN_RUN_CODE_PATH
    headers["Content-Type"] = "text/plain" 
    render :text => "load '#{OPENFOUNDRY_SITE_ADMIN_RUN_CODE_PATH}' ok\n#{$run_code_result}"
  end

  def manage_tags
    flash.now[ :notice ] = session[ :tmsg ] unless session[ :tmsg ].nil?
    session[ :tmsg ] = nil
  end
end
