class ProjectsController < ApplicationController
  
  before_filter :set_project_id

  def set_project_id
    params[:project_id] = params[:id]
  end
  
  def sympa
    @project = Project.find(params[:id])
    if (params[:path] != nil)
      @Path = "http://rt.openfoundry.org/Sympa/" +params[:path] 
    else
      @Path = "http://rt.openfoundry.org/Sympa/lists_by_project/" + @project.unixname
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
    projects = Project.paginate(:page => params[:page], :per_page => 10)
    render(:partial => 'list', :layout => true, :locals => { :projects => projects })
  end

  def show
    @project = Project.find(params[:id])
    @admins = @project.admins
    @members = @project.members
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
      redirect_to :action => 'applied'
    else
      render :action => 'new'
    end
  end

  def edit
    @project = Project.find(params[:id])
    @admins = @project.admins
    @members = @project.members
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
    redirect_to :action => 'edit', :id => params[:id]
  end

  def delete_role
    project = Project.find params[:id]
    raise SandardError unless Role.valid_role? params[:role]

    params[params[:role].to_sym].each do |user_id|
      user = User.find user_id
      if user and project 
        user.has_no_role params[:role], project 
      else
        raise StandardError 
      end
    end
    

    #project_id = params[:id]
    #role = params[:role]
    #ProjectUser.delete_all_in_user_id project_id, params[role.to_sym]
    redirect_to :action => 'edit', :id => params[:id]
#    edit
#    render :action => 'edit'
  end



end
