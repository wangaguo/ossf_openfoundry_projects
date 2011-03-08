class SiteAdmin::ProjectsController < SiteAdmin
  layout 'application'
  require 'fastercsv'
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @projects = Project.paginate(:page => params[:page], :per_page => 100, :order => (sort_column + ' ' + sort_by), :conditions => ["(description LIKE ? OR name LIKE ?) AND status LIKE ?", "%#{query}%", "%#{query}%","%#{sort_status}%" ])
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
    raise "wrong params['invoke']: #{params['invoke']}" if not ['approve', 'reject', 'suspend', 'resume', 'pending'].include?(params['invoke'])

    if ['approve', 'reject', 'pending'].include?(params['invoke']) 
      hr = @project.send(params[:invoke], "___ #{Time.now.in_time_zone(current_user.timezone.to_f.hours).to_s(:rfc822)} - #{current_user().login} ___\n\n" + params[:statusreason] , params[:replymessage])
    else
      hr = @project.send(params[:invoke], params[:statusreason])
    end

    if hr 
      flash[:notice] = "status changed! (#{params[:invoke].upcase})"
      redirect_to project_path(:id => @project.id)
    else
      @bad_project = @project   # bad project only for showing error messages
      @project = Project.find(params[:id])
      render :action => 'change_status_form'
    end
  end
  def sort_column
    @sort = (params[:sortcolumn] || "created_at")
  end
  def sort_by
    @direction = (params[:sortorder] == "desc" ? "asc" : "desc")
  end
  def query
    @query = params[:query]
  end
  def csv
    qt = params[:selection]
    status = params[:status]
    @lists = Project.find(:all, :order=> (params[:sortcolumn] + ' ' + params[:sortorder]), :conditions =>  ["(description LIKE ? OR name LIKE ?) AND status LIKE ?", "%#{qt}%", "%#{qt}%","%#{status}%"])
    csv_string = FasterCSV.generate(:encoding => 'u') do |csv|
      csv << ["Status","Name", "Id" ,"Summary","Description","Creator","Status Reason","Contact Information","Created Date","Updated Date"]
      @lists.each do |project|
        csv << [Project.status_to_s(project.status), project.name , project.id, project.summary, project.description, project.creator, project.statusreason, project.contactinfo, (project.created_at).strftime("%Y-%m-%d %H:%M:%S"), (project.updated_at).strftime("%Y-%m-%d %H:%M:%S")]
      end
    end
    filename = Time.now.strftime("%Y-%m-%d") + ".csv"
    send_data(csv_string,:type => 'text/csv; charset=UTF-8; header=present',:filename => filename)
  end
  def sort_status
    if params[:sortstatus] == "Show All"
      @statusorder = ""
    elsif params[:sortstatus] == "Applying"
      @statusorder = "0"
    elsif params[:sortstatus] == "Suspended"
      @statusorder = "3"
    elsif params[:sortstatus] == "Pending"
      @statusorder = "4"
    elsif params[:sortstatus] == "Ready"
      @statusorder = "2"
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
