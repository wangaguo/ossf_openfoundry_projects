class ReferencesController < ApplicationController 
  layout 'module'
  find_resources :parent => 'project', :child => 'reference', :parent_id_method => 'project_id', :child_rename => 'data_item'
  before_filter :controller_load
  before_filter :check_permission

  def controller_load
    @module_name = _('References')
  end
  
  def index
    list
  end

  def project_references
    @is_all_projects = true
    list
  end
  
  def list
    if params[:project_id].nil? 
      @head = _('Project References')
      layout_name = "application"
      conditions = "references.project_id>0 and #{Project.in_used_projects(:alias => 'projects')}"
      joins = :project
    else
      @module_name = _('References')
      layout_name = "module"
      conditions = "project_id=#{params[:project_id]}"
    end

    if fpermit?("reference", params[:project_id])
      sqlStatus = ""
    else
      sqlStatus = " and references.status = #{Reference::STATUS[:Enabled]}"
    end
    reset_sortable_columns
    add_to_sortable_columns('listing', Reference, 'updated_at', 'updated_at') 
    @data_items = Reference.paginate(:page => params[:page], :per_page => 10, :conditions => [conditions + sqlStatus],
                          :order => sortable_order('listing', :model => Reference, :field => 'updated_at', :sort_direction => :desc),
                          :joins => joins)
    render :layout => layout_name, :template => 'references/list'
  end
  
  def show
  end
  
  def new
    @data_item = Reference.new
  end
  
  def create
    @data_item = Reference.new
    @data_item.source = params[:data_item][:source]
    
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
  end
  
  def update
    @data_item.source = params[:data_item][:source]
    
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
