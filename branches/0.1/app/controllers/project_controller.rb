class ProjectController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @project_pages, @projects = paginate :projects, :per_page => 10
  end

  def show
    @project = Project.find(params[:id])
    @admins = @project.admins
    @members = @project.members

  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(params[:project])
    if @project.save
      flash[:notice] = 'Project was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @project = Project.find(params[:id])
    @admins = @project.admins
    @members = @project.members
  end

  def update
    @project = Project.find(params[:id])
    if @project.update_attributes(params[:project])
      flash[:notice] = 'Project was successfully updated.'
      redirect_to :action => 'show', :id => @project
    else
      render :action => 'edit'
    end
  end

  def destroy
    Project.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def set_role
    project_id = params[:id]
    user_login = params[:user]
    role = params[:role]
    begin
      user_id = User.find_by_login(user_login).id
      ProjectUser.set_role(project_id, user_id, role)
      flash[:notice] = "#{user_login} was successfully added."
    rescue StandardError
      flash[:notice] = "No such user: #{user_login} !!"
    end
    redirect_to :action => 'edit', :id => project_id
  end

  def delete_role
    project_id = params[:id]
    role = params[:role]
    ProjectUser.delete_all_in_user_id project_id, params[role.to_sym]
    redirect_to :action => 'edit', :id => project_id
#    edit
#    render :action => 'edit'
  end



end
