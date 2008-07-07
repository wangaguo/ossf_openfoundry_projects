class NewsController < ApplicationController 
  find_resources :parent => 'project', :child => 'news', :parent_id_method => 'catid', :parent_conditions => 'fpermit?("site_admin", nil) ? "true" : Project.in_used_projects() '
  before_filter :controller_load
  before_filter :check_permission

  def controller_load
  end
  
  def index
    list
  end

  def _home_news
    render :partial => "home_news", :locals => {:newsList => News.home_news}
  end
  
  def project
    @is_all_projects_news = true
    list
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
#  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :list }
  
  def list
    if @is_all_projects_news == true
      @head = _('Project News')
      layout_name = "application"
      conditions = "news.catid<>0 and #{Project.in_used_projects(:alias => 'projects')}"
      joins = :project
    elsif params[:project_id].nil? 
      @head = _('OpenFoundry News')
      layout_name = "application"
      conditions = "catid=0"
    else
      @module_name = _('project_News')
      layout_name = "module"
      conditions = "catid=#{params[:project_id]}"
    end
    if fpermit?("news", params[:project_id])
      sqlStatus = ''
    else
      sqlStatus = " and news.status = #{News::STATUS[:Enabled]}"
    end
    reset_sortable_columns
    add_to_sortable_columns('listing', News, 'subject', 'subject') 
    add_to_sortable_columns('listing', News, 'updated_at', 'updated_at') 
    @news = News.paginate(:page => params[:page], :per_page => 10, :conditions => conditions + sqlStatus,
                          :order => sortable_order('listing', :model => News, :field => 'updated_at', :sort_direction => :desc),
                          :joins => joins
                          )
    render :layout => layout_name, :template => 'news/list'
  end
  
  def show
    if params[:project_id].nil? 
      layout_name = "application"
    else
      @module_name = _('project_News')
      layout_name = "module"
    end
    render :layout => layout_name, :template => 'news/show'
  end
  
  def new
    @news = News.new
  end
  
  def create
    @news = News.new
    @news.subject = params[:news][:subject]
    @news.description = params[:news][:description]
    @news.tags = params[:news][:tags]
    @news.status = params[:news][:status]
    if params[:project_id].nil? 
      project_id = 0
    else
      project_id = params[:project_id]
    end
    @news.catid = project_id
    
    if(params[:news][:updated_at] != "")
      News.record_timestamps = false
      @news.updated_at = local_to_utc(params[:news][:updated_at])
      @news.created_at = DateTime.now 
    end
    
    if @news.save
      flash[:notice] = _('Add Successful')
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @news.updated_at = utc_to_local(@news.updated_at).strftime("%Y-%m-%d %H:%M")
  end
  
  def update
    @news.subject = params[:news][:subject]
    @news.description = params[:news][:description]
    @news.tags = params[:news][:tags]
    @news.status = params[:news][:status]
    if(params[:news][:updated_at] != "")
      News.record_timestamps = false
      @news.updated_at = local_to_utc(params[:news][:updated_at])
    end

    if @news.save
      flash[:notice] = _('Edit Successful')
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @news.destroy
    flash[:notice] = _('Delete Successful')
    redirect_to :action => 'index'
  end

end
