class SiteAdmin::ProjectController < SiteAdmin
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @projects = Project.paginate(:page => params[:page], :per_page => 100, :order => 'created_at desc')
  end

  def show
    @project = Project.find(params[:id])
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



  def change_status_form
    @project = Project.find(params[:id])
  end
  def change_status
    @project = Project.find(params[:id])
    raise "wrong params[:invoke]: #{params[:invoke]}" if not ['approve', 'reject', 'suspend', 'resume'].include?(params[:invoke])
    if @project.send(params[:invoke], params[:statusreason])
      flash[:notice] = 'status changed!'
      redirect_to :action => 'show', :id => @project.id
    else
      @bad_project = @project   # bad project only for showing error messages
      @project = Project.find(params[:id])
      render :action => 'change_status_form'
    end
  end

#  def approve
#    Project.find(params[:id]).approve
#    redirect_to :action => 'show', :id => @project.id
#  end
#  def reject
#    Project.find(params[:id]).reject(params[:statusreason])
#    redirect_to :action => 'show', :id => @project.id
#  end
end
