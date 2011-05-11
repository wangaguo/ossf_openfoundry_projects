class JobsController < ApplicationController 
  layout 'module'
  find_resources :parent => 'project', :child => 'job', :parent_id_method => 'project_id', :child_rename => 'data_item'
  before_filter :controller_load
  before_filter :check_permission

  def controller_load
    @module_name = _('Help Wanted')
  end
  
  def index
    list
  end

  def project_jobs
    @is_all_projects = true
    list
  end
  
  def list
    if params[:project_id].nil? 
      @module_name = _('Project Help Wanted')
      layout_name = "normal"
      conditions = "jobs.project_id>0 and #{Project.in_used_projects(:alias => 'projects')}"
      joins = :project
    else
      @module_name = _('Help Wanted')
      layout_name = "module"
      conditions = "project_id=#{params[:project_id]}"
    end

    if fpermit?("job", params[:project_id])
      sqlStatus = ""
    else
      sqlStatus = " and jobs.status = #{Job::STATUS[:Enabled]}"
    end
    reset_sortable_columns
    add_to_sortable_columns('listing', Job, 'subject', 'subject') 
    add_to_sortable_columns('listing', Job, 'updated_at', 'updated_at') 
    @data_items = Job.paginate(:page => params[:page], :per_page => 10, :conditions => [conditions + sqlStatus],
                          :order => sortable_order('listing', :model => Job, :field => 'updated_at', :sort_direction => :desc),
                          :joins => joins)
    render :layout => layout_name, :template => 'jobs/list'
  end
  
  def show
    @data_item.due = @data_item.due.strftime("%Y-%m-%d") if !@data_item.due.nil?
    @module_name = @data_item.subject
  end
  
  def new
    @data_item = Job.new
    @module_name = _('Add Job')
  end
  
  def create
    @data_item = Job.new
    @data_item.subject = params[:data_item][:subject]
    @data_item.description = params[:data_item][:description]
    @data_item.requirement = params[:data_item][:requirement]
    @data_item.due = params[:data_item][:due]
    @data_item.project_id = params[:project_id]
    @data_item.status = params[:data_item][:status]
    if @data_item.save
      flash[:notice] = _('Add Successful')
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @data_item.due = @data_item.due.strftime("%Y-%m-%d") if !@data_item.due.nil?
    @module_name = _('Edit')
  end
  
  def update
    @data_item.subject = params[:data_item][:subject]
    @data_item.description = params[:data_item][:description]
    @data_item.requirement = params[:data_item][:requirement]
    @data_item.due = params[:data_item][:due]
    @data_item.status = params[:data_item][:status]
    if @data_item.save
      flash[:notice] = _('Edit Successful')
      redirect_to :action => 'show', :id => @data_item
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @data_item.destroy
    flash[:notice] = _('Delete Successful')
    redirect_to :action => 'index'
  end

end
