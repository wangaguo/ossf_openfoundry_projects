class CitationsController < ApplicationController 
  layout 'module'
  find_resources :parent => 'project', :child => 'citation', :parent_id_method => 'project_id', :child_rename => 'data_item'
  before_filter :controller_load
  before_filter :check_permission

  def controller_load
    @module_name = _('Citations')
  end
  
  def index
    list
  end

  def project_citations
    @is_all_projects = true
    list
  end
  
  def list
    if params[:project_id].nil? 
      @head = _('Project Citations')
      layout_name = "application"
      conditions = "citations.project_id>0 and #{Project.in_used_projects(:alias => 'projects')}"
      joins = :project
    else
      @module_name = _('Citations')
      layout_name = "module"
      conditions = "project_id=#{params[:project_id]}"
    end

    if fpermit?("citation", params[:project_id])
      sqlStatus = ""
    else
      sqlStatus = " and citations.status = #{Citation::STATUS[:Enabled]}"
    end
    reset_sortable_columns
    add_to_sortable_columns('listing', Citation, 'project_title', 'project_title') 
    add_to_sortable_columns('listing', Citation, 'updated_at', 'updated_at') 
    @data_items = Citation.paginate(:page => params[:page], :per_page => 10, :conditions => [conditions + sqlStatus],
                          :order => sortable_order('listing', :model => Citation, :field => 'updated_at', :sort_direction => :desc),
                          :joins => joins)
    render :layout => layout_name, :template => 'citations/list'
  end
  
  def show
    @module_name = @data_item.project_title
  end
  
  def new
    @data_item = Citation.new
    @module_name = _('Add Citation')
  end
  
  def create
    @data_item = Citation.new(params[:data_item])
    @data_item.project_id = params[:project_id]
    if @data_item.save
      flash[:notice] = _('Add Successful')
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @module_name = _('Edit')
  end
  
  def update
    if @data_item.update_attributes(params[:data_item])
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
