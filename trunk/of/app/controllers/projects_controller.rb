class ProjectsController < ApplicationController
  helper :projects
  layout 'module'
  before_filter :set_project_id
  before_filter :login_required, :except => [:set_project_id, :sympa, :viewvc, :websvn, :index, :list, :show, :join_with_separator, :role_users, :vcs_access, :test_action, :new_projects_feed]
  before_filter :set_project

  before_filter :check_permission
  def set_project
    if params[:id]
      @project = get_project_by_id_or_name(params[:id]) { |id| redirect_to :id => id }
    end
  end
  
  def set_project_id
    params[:project_id] = params[:id]
    @module_name = _('Basic Information')
  end
  
  def sympa
    @module_name = _('Mailing List')
    if (params[:path] != nil)
      @Path = OPENFOUNDRY_OF_URL + "#{params[:path]}" 
    else
      @Path = OPENFOUNDRY_SYMPA_URL + "lists_by_project/" + @project.name
    end

    if (params[:projectUnixName] != nil)
      @sympa_new_url = "/projects/" + Project.find_by_name("#{params[:projectUnixName]}", :select => 'id').id.to_s + "/sympa"
      
      @sympa_new_url += "?path=#{params[:path]}" if !(params[:path] =~ /(info)/).nil?
      
      redirect_to @sympa_new_url
    end
  end
  
  def viewvc
    @module_name = _('Version Control')
    case @project.vcs
    when Project::VCS[:CVS]
      @Path = OPENFOUNDRY_VIEWVC_CVS_URL + @project.name
    when Project::VCS[:SUBVERSION]
      @Path = OPENFOUNDRY_VIEWVC_SVN_URL + "?root=" + @project.name
    when Project::VCS[:REMOTE], Project::VCS[:NONE], Project::VCS[:SUBVERSION_CLOSE]
      vcs_access
      render :template => 'projects/vcs_access'
    else
      render :text => _("System error. Please contact the site administrator.")
    end
  end

  def websvn 
    @module_name = _('Version Control')
    case @project.vcs
    when Project::VCS[:CVS]
      render :text => _("The WebSVN can't support CVS. Please use ViewVC.")
    when Project::VCS[:SUBVERSION]
      @Path = OPENFOUNDRY_WEB_SVN_URL + "listing.php?repname=" + @project.name
      render :template => 'projects/viewvc'
    when Project::VCS[:REMOTE], Project::VCS[:NONE], Project::VCS[:SUBVERSION_CLOSE]
      vcs_access
      render :template => 'projects/vcs_access'
    else
      render :text => _("System error. Please contact the site administrator.")
    end
  end

  def index
    list
    #render :action => 'list'
    logger.debug "session['user']: " + session[:user].inspect
  end

  def list_n3 #it is a kind of rdf format that list all projects
    txt="\t@prefix doap:<http://usefulinc.com/ns/doap#>.\n#{Project.in_used.find(:all).map{|p| 
       "<#{project_url p.id}#self> a doap:Project."}.join("\n")}"
    headers["Content-Type"] = "text/n3; charset=utf-8" 
    render :text => txt
  end
  private :list_n3
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  #verify :method => :post, :only => [ :destroy, :create, :update ],
  #       :redirect_to => { :action => :list }

  def list
    if(params[:format] == 'n3')
      list_n3
      return
    end
    reset_sortable_columns
    add_to_sortable_columns('listing', Project, 'summary', 'summary') 
    add_to_sortable_columns('listing', Project, 'created_at', 'created_at')
    add_to_sortable_columns('listing', Release, 'created_at', 'latest_file')
    add_to_sortable_columns('listing', Project, 'project_counter', 'project_counter')
    
    # params[:cat] => 'maturity' / 'platform' ...
    # params[:name] => 'beta' / 'windows' ...
    query = Project.in_used_projects(:alias => 'projects')
    if params[:cat] =~ /^(maturity|license|contentlicense|platform|programminglanguage)$/
      if params[:cat] != '' && params[:name] != ''
        if params[:cat] !~ /^(maturity)$/
          name = '%,' + params[:name] + ',%'
        else
          name = params[:name]
        end
        query = [params[:cat] + " like ? and #{Project.in_used_projects}", name]
      end
      if params[:cat] =~ /^(maturity|license|contentlicense)$/
        if params[:cat] =~ /^(contentlicense)$/
          @filter_by = eval("Project::content_license_to_s(#{params[:name]})")
        else
          @filter_by = eval("Project::#{params[:cat]}_to_s(#{params[:name]})")
        end
      else
        @filter_by = params[:name]
      end
    end
    
    projects = nil
    [params[:page], 1].each do |page|
      projects = Project.paginate(:page => page, :per_page => 10, :conditions => query,
                 :include => [:releases],
                 :order => sortable_order('listing', :model => Project, :field => 'summary', :sort_direction => :asc) )
      break if not projects.out_of_bounds?
    end
    render(:partial => 'list', :layout => 'application', :locals => { :projects => projects })
  end

  def show
    @participents = User.find_by_sql("
      select distinct U.id, U.login, U.icon, R.name as role_name
        from users U
          inner join roles_users RU on U.id = RU.user_id
          inner join roles R on RU.role_id = R.id
        where
          R.authorizable_id = #{@project.id} and
          R.authorizable_type= 'Project'
        order by U.id
    ")    
  end

  def new
    @project = Project.new
  end

  def join_with_separator()
    h = params["project"]
    h["programminglanguage"] = "," + normalize_values(Project::PROGRAMMING_LANGUAGES, split_strip_compact_array((h["programminglanguage"] || {}).values)) {|x| x.downcase }.flatten.join(",") + ","
    h["platform"] = "," + normalize_values(Project::PLATFORMS, split_strip_compact_array((h["platform"] || {}).values)) {|x| x.downcase }.flatten.join(",") + ","
    h["license"] = "," + normalize_values(Project::LICENSE_DISPLAY_KEYS.map(&:to_s), split_strip_compact_array((h["license"] || {}).values))[0].join(",") + ","
    h["contentlicense"] = "," + normalize_values(Project::CONTENT_LICENSE_DISPLAY_KEYS.map(&:to_s), split_strip_compact_array((h["contentlicense"] || {}).values))[0].join(",") + ","
  end

  def create
    join_with_separator
    params[:project][:nsccode] = params[:project][:nsccode].split(/,/).map(&:strip).map(&:upcase).grep(/^NSC/)

    @project = Project.apply(params[:project], current_user())
    if @project.errors.empty?
      redirect_to :action => 'applied'
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    params[:project].delete(:name)
    join_with_separator
    params[:project][:nsccode] = params[:project][:nsccode].split(/,/).map(&:strip).map(&:upcase).grep(/^NSC/)

    old_redirecturl = @project.redirecturl
    old_vcs = @project.vcs
    old_summary = @project.summary
    if @project.update_attributes(params[:project])
      flash[:notice] = _('Project was successfully updated.')
      changed = []
      changed << _("Project|Redirecturl") if @project.redirecturl != old_redirecturl
      changed << _("Project|Vcs") if @project.vcs != old_vcs
      if not changed.empty?
        flash[:notice] +=  " " + _('It may take 5 minutes for %s settings to take effect.') % changed.join("/")
      end

      # send message to rt module for sync
      if @project.summary != old_summary
        ApplicationController::send_msg(TYPES[:project], ACTIONS[:update], {'id' => @project.id, 'name' => @project.name, 'summary' => @project.summary})
      end 

      redirect_to :action => 'show', :id => @project
    else
      render :action => 'edit'
    end
  end

  def destroy
    Project.find(params[:id]).destroy
    redirect_to :action => 'index'
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
              flash.now[:warning] = _('Group "Admin" CAN NOT be EMPTY!') 
              old_r.users << u #TODO: better recovery
              member_edit #if flag_changed
              render :action => :member_edit, :layout => 'module_with_flash'
              return
            end
            old_r.save
            r.users << u unless r.users.include? u
            r.save
            #u.roles.delete(old_r)
            #u.roles << r unless u.roles.include? r
            #u.save
            flag_changed = true
            before = u.functions_for(r.authorizable_id)
            after = u.functions_for(r.authorizable_id)
            added = after - before
            removed = before - after
            added.each do |f|
              ApplicationController::send_msg('function','create',
                                              {:function_name => f.name, 
                                                :user_id => u.id,
                                                :project_id => r.authorizable_id
                                              })
            end
            removed.each do |f|
              ApplicationController::send_msg('function','remove',
                                              {:function_name => f.name, 
                                                :user_id => u.id,
                                                :project_id => r.authorizable_id
                                              })
            end
            flash.now[:notice] = 
              _('Move User "%{user}" from Group "%{old_role}" to Group "%{role}"') % 
            {:user => u.login, :old_role => old_r.name, :role => r.name}
          else
            flash.now[:warning] = 
              _('You can\'t move User between Groups that belong to different Projects.')
          end
        else
          before  = u.functions_for(r.authorizable_id)
          u.roles << r unless u.roles.include? r
          u.save
          flag_changed = true
          after = u.functions_for(r.authorizable_id)
          added = after - before
          added.each do |f|
            ApplicationController::send_msg('function','create',
                                            {:function_name => f.name, 
                                              :user_id => u.id,
                                              :project_id => r.authorizable_id
                                            })
          end
          flash.now[:notice] = 
            _('Add User "%{user}" into Group "%{role}"') % 
          {:user => u.login, :role => r.name} 
        end
      else
        flash.now[:warn] = 
          _('Group "%{role}" doesn\'t exist!') % 
        {:role => r.name}
      end
    else
      flash.now[:warning] = 
        _('User "%{user}" doesn\'t exist!') % 
      {:user => u.login}
    end
    member_edit #if flag_changed
    render :action => :member_edit, :layout => 'module_with_flash'
    #    project = Project.find params[:id]
    #    begin
    #    user = User.find_by_login params[:user], :conditions => User.verified_users
    #    project.set_role(params[:role], user)
    #      rescue
    #      flash[:warning] = _("Invalid User!")
    #    end
    #    redirect_to :action => 'roles_edit', :id => params[:id]
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
          before = u.functions_for(r.authorizable_id)
          r.users.delete u
          unless r.valid?
            flash.now[:warning] = _('Group "Admin" CAN NOT be EMPTY!')
            r.users << u #TODO: better recovery
            member_edit #if flag_changed
            render :action => :member_edit, :layout => 'module_with_flash'
            return
          end
          r.save
          #u.roles.delete(r)
          #u.save
          after = u.functions_for(r.authorizable_id)
          removed = before -after
          flag_changed = true
          after = u.functions_for(r.authorizable_id)
          removed = before - after
          removed.each do |f|
            ApplicationController::send_msg('function','remove',
                                            {:function_name => f.name, 
                                              :user_id => u.id,
                                              :project_id => r.authorizable_id
                                            })
          end
          flash.now[:notice] = 
            _('Remove User "%{user}" from Group "%{role}"') % 
          {:user => u.login, :role => r.name}
        else
          flash.now[:warning] = 
            _('Group "%{role}" doesn\'t exist!') % 
          {:role => r.name}
        end
      else
        flash.now[:warning] = 
          _('User "%{user}" doesn\'t exist!') % 
        {:user => u.login}
      end
    end
    member_edit #if flag_changed
    render :action => :member_edit, :layout => 'module_with_flash'
#    params[params[:role].to_sym].each do |user_id|
#      user = User.find user_id
#      if user and project
#        user.has_no_role params[:role], project
#      else
#        raise StandardError 
#      end
#    end
  end

  def member_edit
    @module_name = _('project_Member Control')
    @roles = @project.roles
    @users_map = @roles.collect{|r| r.users}
  end
  
  def role_users
    @role = Role.find(params[:role])
    if(@role.authorizable_id == @project.id)
      @users = @role.users
    end
    render :layout => false 
  end
  
  def permission_edit
    @module_name = _('project_Permission Control')
    @roles = @project.roles.reject{|r| !(r.editable? )}
    @functions_map = @roles.collect{|r| r.functions.collect{|f| f.id } }
    @all_functions = Function.find :all
  end  
    
  def role_edit
    @role = Role.find(params[:role])
    @role_functions = @role.functions
    @functions = Function.find(:all)
    #page[:role_new].hide
    #render :layout => false
    if(@role.name.upcase == "ADMIN" || @role.name.upcase == "MEMBER")
      #render :text => "This role can't be changed!", :layout => false
      render :layout => false
    else
      render :layout => false
    end
  end
  
  def group_update
    if Role.exists? params[:role] and role = Role.find(params[:role])
    if(role.authorizable_id == @project.id)
      if !(role.name.upcase == "ADMIN" || role.name.upcase == "MEMBER")
        role.name = params[:name]
      end
      if (role.name.upcase != "ADMIN" && role.save)
        updated = params[:functions] || {}
        unless( updated.keys == role.functions.map{|f| f.id} )
          after = updated.keys.collect{|id| Function.find(id)}
          before = role.functions
          added = after - before
          removed = before - after
          role.functions.delete_all
          role.functions = after
          role.save

          #send message for everyone in that role
          project_id = role.authorizable_id
          role.users.each do |u|
            removed.each do |f|
              ApplicationController::send_msg('function','remove',
                                              {:function_name => f.name, 
                                                :user_id => u.id,
                                                :project_id => project_id
                                              })
            end
            added.each do |f|
              ApplicationController::send_msg('function','create',
                                              {:function_name => f.name, 
                                                :user_id => u.id,
                                                :project_id => project_id
                                              })
            end
          end
        end
        flash.now[:notice] = _('Permission was successfully updated.')
      end
      #@role.name = params[:name]
    end
    end
    #page.reload
#    page[:greeting].update "Greetings, " + params[:name]
#    page[:greeting].visual_effect :grow
#    page.select("form").first.reset
    #send_msg(TYPES[:project], ACTIONS[:create], "hello world")
    permission_edit
    render :action => 'permission_edit', :layout => 'module_with_flash'
  end
   
  def group_create
    role = @project.roles.new
    if(role.authorizable_id == @project.id)
      role.name = params[:name]
      if(role.name.upcase != "ADMIN" && role.name.upcase != "MEMBER")
        role.authorizable_type = "Project"
        if role.save
          flash.now[:notice] = _('Role "%{name}" was successfully created.') %
            {:name => role.name}
        end
      end
    end
    permission_edit
    render :action => 'permission_edit', :layout => 'module_with_flash'
  end

  def group_delete
    if Role.exists?(params[:role]) and role = Role.find(params[:role])
    if(role.name.upcase == "ADMIN" || role.name.upcase == "MEMBER")
      flash.now[:warning] = _('Admin and Member can\'t be deleted.')
#      render :update do |page|
#        page.alert "Admin and Member cant's be delete."
#        page.visual_effect :highlight, 'role_new'
#      end
    else
      @project.roles.delete role
      role.destroy
      flash.now[:notice] = _('Role "%{name}" was successfully deleted.') %
            {:name => role.name}
#      render :update do |page|
#        page[:role_new].reload
#      end  
    end
    else
      flash.now[:error] = _('Role id not found!')
    end
    permission_edit
    render :action => 'permission_edit', :layout => 'module_with_flash'
  end
   
  def new_projects_feed
    new_projects = Project.find(:all, :conditions => Project.in_used_projects , :order => "created_at desc", :limit => 10)

    feed_options = {
      :feed => {
        :title       => _("OpenFoundry: New Projects Feed"),
        :description => _("New projects on OpenFoundry"),
        :link        => 'of.openfoundry.org',
        :language    => 'UTF-8'
      },
      :item => {
        :title => :summary,
        :description => :description,
        :link => lambda { |p| project_url(:id => p.id)}
      }
    }
    respond_to do |format|
      format.rss { render_rss_feed_for new_projects, feed_options }
      format.xml { render_atom_feed_for new_projects, feed_options }
    end
  end
  
  def vcs_access
    @module_name = _('Version Control System: How to Access')
    @vcs = @project.vcs
    @src = ""
    @vcs_desc = @project.vcsdescription
    case(@vcs)
    when Project::VCS[:SUBVERSION], Project::VCS[:SUBVERSION_CLOSE] 
      @src = "svn co http://svn.openfoundry.org/#{@project.name} #{@project.name}"
    when Project::VCS[:CVS]
      @src = "cvs -d :ext:cvs\@cvs.openfoundry.org:/cvs co #{@project.name}"
    when Project::VCS[:REMOTE]
    else
    end
  end
  def the_rest
    render :text => 'ohoh'
  end
  def test_action
  end
end
