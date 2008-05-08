class ProjectsController < ApplicationController
  layout 'module'
  before_filter :set_project_id
  
  def set_project_id
    params[:project_id] = params[:id]
    @module_name = "專案資訊"
  end
  
  def sympa
    @project = Project.find(params[:id])
    if (params[:path] != nil)
      @Path = "http://rt.openfoundry.org/Sympa/" +params[:path] 
    else
      @Path = "http://rt.openfoundry.org/Sympa/lists_by_project/" + @project.unixname
    end
  end
  
  def viewvc
    @project = Project.find(params[:id])
    @Path = OPENFOUNDRY_VIEWVC_URL + "?root=" + @project.unixname
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
    projects = Project.paginate(:page => params[:page], :per_page => 10)
    if projects.out_of_bounds?
      projects = Project.paginate(:page => 1, :per_page => 10)
    end
    render(:partial => 'list', :layout => true, :locals => { :projects => projects })
  end

  def show
    @project = Project.find(params[:id])
    @roles = @project.roles
  end

  def new
    login_required #_("create project require login")
    @project = Project.new
  end

  def join_with_separator(hash, *keys)
    unless hash.nil?
      keys.each do |k|
        k = k.to_s
        hash[k] = hash[k].values.grep(/./).join(",") unless hash[k].nil?  
      end
    end
  end

  def create
    login_required #_("create project require login")
    join_with_separator(params[:project], :platform, :programminglanguage, :intendedaudience)

    @project = Project.apply(params[:project], current_user())
    if @project.errors.empty?
      ApplicationController::send_msg(TYPES[:project], ACTIONS[:create], {'id' => @project.id, 'name' => @project.summary, 'summary' => @project.description})
      redirect_to :action => 'applied'
    else
      render :action => 'new'
    end
  end

  def edit
    @project = Project.find(params[:id])
    redirect_to :action => 'index' if not current_user().has_role?("Admin", @project)
  end

  def update
    @project = Project.find(params[:id])
    join_with_separator(params[:project], :platform, :programminglanguage, :intendedaudience)
    if @project.update_attributes(params[:project])
      flash[:notice] = 'Project was successfully updated.'
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
    user = User.find_by_login params[:user]
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
    @project = Project.find(params[:id])
    @roles = @project.roles
  end
  
  def role_users
    @project = Project.find(params[:id])
    @role = Role.find(params[:role])
    if(@role.authorizable_id == @project.id)
      @users = @role.users
    end
    render :layout => false 
  end
  
  def role_edit
    @project = Project.find(params[:id])
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
    @project = Project.find(params[:id])
    @role = Role.find(params[:role])
    if(@role.authorizable_id == @project.id)
      if !(@role.name.upcase == "ADMIN" || @role.name.upcase == "MEMBER")
        @role.name = params[:name]
      end
      if @role.save
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
    redirect_to :action => 'role_new', :id => params[:id]
  end
  
  def role_new
    @project = Project.find(params[:id])
    @roles = @project.roles
    render :partial => 'role_new', :layout => false
  end
  
  def role_create
    @project = Project.find(params[:id])
    @role = @project.roles.new
    if(@role.authorizable_id == @project.id)
      @role.name = params[:name]
      @role.authorizable_type = "Project"
      if @role.save
        flash[:notice] = 'Role was successfully created.'
      end
    end
    redirect_to :action => 'role_new', :id => params[:id]
  end

  def role_destroy
    @project = Project.find(params[:id])
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
end
