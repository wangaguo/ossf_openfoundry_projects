class SiteAdmin::SiteAdminController < SiteAdmin
  layout 'application'
  require 'fastercsv'

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
    session[:effective_user] = User.find(params[:id])
    redirect_to dashboard_user_path
  end

  def index
    cookies['HeaderOnOff'] = 'OFF'
  end

  def gettext_cache_switch
    GetText.cached = !GetText.cached? 
    render :text => "switch to #{GetText.cached?} @ #{Time.now}"
  end

  def aaf_rebuild
    #User.rebuild_index(Project,Release,News,Fileentity)
    Project.rebuild_index
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

      mail = UserNotify.create_site_mail(@mail.subject, @mail.message.html_safe)
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
          @mail.filter = line.gsub(/[' ]/, "")
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

  def member_change
    flag_changed = false
    params['u'] =~ /role_(\d+)_user_(\d+)/
    drag_role_id = $1
    user_id = $2
    params['r'] =~ /role_(\d+)/
    drop_role_id = $1
    if u=User.find(user_id)
      if r=Role.find(drop_role_id)
        #remember functions before
        if drag_role_id.to_i !=0 and old_r=Role.find(drag_role_id)
          if drag_role_id == drop_role_id #fom A to A => nothing happen
            flash.now[:warning] = _('No Operation...')
          elsif r.authorizable_id == old_r.authorizable_id #the same project?
            old_r.users.delete(u)
            unless old_r.valid?
              flash.now[:warning] = _('Group "Admin" CAN NOT be EMPTY.')
              old_r.users << u #TODO: better recovery
              member_edit #if flag_changed
              render :action => :member_edit, :layout => 'module_with_flash'
              return
            end
            old_r.save
            r.users << u unless r.users.include? u
            r.save

            flag_changed = true
            flash.now[:notice] = _( 'Move User to Group' ) + " #{ r.name }"
          else
            flash.now[:warning] =
              _('You can\'t move User between Groups that belong to different Projects.')
          end
        else
          u.roles << r unless u.roles.include? r
          u.save
          flag_changed = true
          flash.now[:notice] = _( 'Add User into Group' ) + " #{ r.name }"
        end
      else
        flash.now[:warn] = _( 'Group doesn\'t exist!' ) + ": #{ r.name }"
      end
    else
      flash.now[:warning] = _( 'User doesn\'t exist!' ) + ": #{ u.login }"
    end
    member_edit #if flag_changed
    render :action => :member_edit, :layout => 'module_with_flash'
  end

  def member_delete
    flag_changed = false
    params['u'] =~ /role_(\d+)_user_(\d+)/
    role_id = $1
    if role_id.to_i < 1 #drag 'new user' 
      flash.now[:warning] =
          _('You can\'t delete User belongs to This Group!')
    else
      user_id = $2
      if u=User.find(user_id)
        if r=Role.find(role_id)
          #remember functions before
          r.users.delete u
          unless r.valid?
            flash.now[:warning] = _('Group "Admin" CAN NOT be EMPTY.')
            r.users << u #TODO: better recovery
            member_edit #if flag_changed
            render :action => :member_edit, :layout => 'module_with_flash'
            return
          end
          r.save
          flag_changed = true
          flash.now[:notice] =
            _('Remove User from Group')

        else
          flash.now[:warning] = _( 'Group doesn\'t exist!' ) + ": #{ r.name }"
        end
      else
        flash.now[:warning] = _( 'User doesn\'t exist!' ) + ": #{ u.login }"
      end
    end
    member_edit #if flag_changed
    render :action => :member_edit, :layout => 'module_with_flash'
  end

  def member_edit
    @module_name = _('Site Member Control')
    @roles = Role.find_all_by_authorizable_type("site")
    @users_map = @roles.collect{|r| r.users}
  end
  def csv
    qt = params[:selection]
    conditions = params[:nscconditions]
    vcs_check = params[:vcscheck]    
    i = 0
    @lists = Project.find(:all, :joins=>:tags, :conditions => [conditions + "AND (projects.name LIKE ? OR projects.description LIKE ? OR tags.name LIKE ?)", "%#{qt}%", "%#{qt}%", "%#{qt}%"])
    csv_string = FasterCSV.generate(:encoding => 'u') do |csv|
      csv << ["編號", "計畫編號","專案ID","OpenFoundry專案代號(專案名稱)","計畫名稱","專案描述", "成熟度", "建立日期", "建立者", "下載次數", "VCS", "VCS Info"]
      @lists.each do |project|
        if vcs_check == 'true'
          abc = system "svn info http://svn.openfoundry.org/#{project.name} > /tmp/nsc_svn.log"
          log = ""
          File.open("/tmp/nsc_svn.log").each{|line| log += "#{line}<br/>"}
        end
        u = User.find_by_id(project.creator)
        csv << [(i+=1).to_s, project.tag_list.names , project.id, project.name, project.summary, project.description, project.maturity_to_s, (project.created_at).strftime("%Y-%m-%d"), "#{u.login} (#{u.realname})" , project.project_counter, Project.vcs_to_s(project.vcs), log]
      end
    end
    filename = Time.now.strftime("%Y-%m-%d") + ".csv"
    send_data(csv_string, :type => 'text/csv; charset=UTF-8; header=present',:filename => filename)
  end

  def manage_tags
    flash.now[ :notice ] = session[ :tmsg ] unless session[ :tmsg ].nil?
    session[ :tmsg ] = nil
  end

  def nsc_download
  end
end
