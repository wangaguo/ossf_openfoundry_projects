class ProjectsController < ApplicationController
  helper :projects
  layout 'module'
  before_filter :set_project_id
  before_filter :login_required, :except => [:set_project_id, :sympa, :viewvc, :index, :list, :show, :join_with_separator, :role_users, :vcs_access]
  before_filter :set_project

  before_filter :check_permission
  def set_project
    if params[:id]
      @project = ProjectsController.get_project_by_id_or_name(params[:id], self) { |id| redirect_to :id => id }
    end
  end
  def self.get_project_by_id_or_name(id_or_name, controller)
    rtn = nil
    case id_or_name
    when /^\d+$/
      rtn = Project.find_by_id(id_or_name, :conditions => Project.in_used_projects())
    when Project::NAME_REGEX
      if rtn = Project.find(:first, :select => 'id', :conditions => ["name = ? and #{Project.in_used_projects}", id_or_name])
        yield rtn.id
      end
    end
    if not rtn
      controller.send(:flash)[:warning] = "Project '#{id_or_name}' does not exist, or it has be deactivated."
      controller.send(:redirect_to, "/")
    end
    rtn
  end

  
  def set_project_id
    params[:project_id] = params[:id]
    @module_name = _('Project Infomation')
  end
  
  def sympa
    @module_name = _('Mailing List')
    if (params[:path] != nil)
      @Path = OPENFOUNDRY_SYMPA_URL + "/#{params[:path]}" 
    else
      @Path = OPENFOUNDRY_SYMPA_URL + "/lists_by_project/" + @project.name
    end
  end
  
  def viewvc
    @module_name = _('Version Control')
    case @project.vcs
    when Project::VCS[:CVS]
      @Path = OPENFOUNDRY_VIEWVC_URL + @project.name
    when Project::VCS[:SUBVERSION]
      @Path = OPENFOUNDRY_VIEWVC_URL + "?root=" + @project.name
    when Project::VCS[:REMOTE], Project::VCS[:NONE]
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

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  #verify :method => :post, :only => [ :destroy, :create, :update ],
  #       :redirect_to => { :action => :list }

  def list
    reset_sortable_columns
    add_to_sortable_columns('listing', Project, 'summary', 'summary') 
    add_to_sortable_columns('listing', Project, 'created_at', 'created_at')
    add_to_sortable_columns('listing', Project, 'project_counter', 'project_counter')
    
    # params[:cat] => 'maturity' / 'platform' ...
    # params[:name] => 'beta' / 'windows' ...
    query = Project.in_used_projects
    if params[:cat] =~ /^(maturity|license|contentlicense|platform|programminglanguage)$/
      if params[:cat] != '' && params[:name] != ''
        if params[:cat] !~ /^(maturity)$/
          name = '%,' + params[:name] + ',%'
        else
          name = params[:name]
        end
        query = [params[:cat] + " like ? and #{Project.in_used_projects}", name]
      end
    end
    
    projects = nil
    [params[:page], 1].each do |page|
      projects = Project.paginate(:page => page, :per_page => 10, :conditions => query,
                                :order => sortable_order('listing', :model => Project, :field => 'summary', :sort_direction => :asc) )
      break if not projects.out_of_bounds?
    end
    render(:partial => 'list', :layout => 'application', :locals => { :projects => projects })
  end

  def show
    @participents = User.find_by_sql("select distinct(U.id),U.login,U.icon from users U join roles_users RU join roles R where U.id = RU.user_id and RU.role_id = R.id and R.authorizable_id = #{@project.id} and R.authorizable_type='Project' order by U.id")
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

    if @project.update_attributes(params[:project])
      flash[:notice] = _('Project was successfully updated.')
      redirect_to :action => 'show', :id => @project
    else
      render :action => 'edit'
    end
  end

  def destroy
    Project.find(params[:id]).destroy
    redirect_to :action => 'index'
  end

  def set_role
    project = Project.find params[:id]
    user = User.find_by_login params[:user], :conditions => User.verified_users
    project.set_role(params[:role], user)
    redirect_to :action => 'roles_edit', :id => params[:id]
  end

  def delete_role
    project = Project.find params[:id]
#    raise SandardError unless Role.valid_role? params[:role]
    params[params[:role].to_sym].each do |user_id|
      user = User.find user_id
      if user and project
        user.has_no_role params[:role], project
      else
        raise StandardError 
      end
    end
    
    redirect_to :action => 'roles_edit', :id => params[:id]
  end

  def roles_edit
    @roles = @project.roles
  end
  
  def role_users
    @role = Role.find(params[:role])
    if(@role.authorizable_id == @project.id)
      @users = @role.users
    end
    render :layout => false 
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
  
  def role_update
    @role = Role.find(params[:role])
    if(@role.authorizable_id == @project.id)
      if !(@role.name.upcase == "ADMIN" || @role.name.upcase == "MEMBER")
        @role.name = params[:name]
      end
      if (@role.name.upcase != "ADMIN" && @role.save)
        @role.functions.delete_all
        if !params[:functions].nil?
          for function_id in params[:functions].keys
            @role.functions << Function.find(function_id)
          end
        end
        flash[:notice] = 'Role was successfully updated.'
      end
      #@role.name = params[:name]
    end
    #page.reload
#    page[:greeting].update "Greetings, " + params[:name]
#    page[:greeting].visual_effect :grow
#    page.select("form").first.reset
    #send_msg(TYPES[:project], ACTIONS[:create], "hello world")

    redirect_to :action => 'role_new', :id => params[:id]
  end
  
  def role_new
    @roles = @project.roles
    render :partial => 'role_new', :layout => false
  end
  
  def role_create
    @role = @project.roles.new
    if(@role.authorizable_id == @project.id)
      @role.name = params[:name]
      if(@role.name.upcase != "ADMIN" && @role.name.upcase != "MEMBER")
        @role.authorizable_type = "Project"
        if @role.save
          flash[:notice] = 'Role was successfully created.'
        end
      end
    end
    redirect_to :action => 'role_new', :id => params[:id]
  end

  def role_destroy
    @roles = @project.roles
    role = Role.find(params[:role])
    if(role.name.upcase == "ADMIN" || role.name.upcase == "MEMBER")
      render :update do |page|
        page.alert "Admin and Member cant's be delete."
        page.visual_effect :highlight, 'role_new'
      end
    else
      role.destroy
      render :update do |page|
#       page[:role_new].replace_html "sdlfkj" :partial => "role_new"
        page[:role_new].reload
      end  
#      redirect_to :action => 'role_new', :id => params[:id]
    end
  end
  
  def vcs_access
    @module_name = _('Subversion/CVS Access')
    @vcs = @project.vcs
    @src = ""
    @vcs_desc = @project.vcsdescription
    case(@vcs)
    when Project::VCS[:SUBVERSION]
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
end
