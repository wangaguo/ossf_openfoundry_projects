class NewsController < ApplicationController 
  before_filter :permit_redirect

  def permit_redirect
    if params[:id] != nil
      @news = News.find(params[:id])
      if @news.catid == 0
        if (params[:project_id] != nil)
          redirect_to "/news/" + @news.id.to_s
        end
      else
        if params[:project_id] != @news.catid.to_s
          redirect_to :project_id => @news.catid, :id => @news.id
        else
          @project = Project.find(@news.catid)
        end
      end
    elsif params[:project_id] != nil
      @project = Project.find(params[:project_id])
    end
    
    if ["new", "create", "edit", "update", "destroy"].include? action_name
      unless permit?("site_admin") || permit?("admin of :project")
        redirect_to :action => 'index'
      end
    end
  end
  
  def index
    list
    render :action => 'list'
  end

  def _home_news
    render :partial => "home_news", :locals => {:newsList => News.home_news}
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
#  verify :method => :post, :only => [ :destroy, :create, :update ], :redirect_to => { :action => :list }
  
  def list
    if params[:project_id].nil? 
      project_id = 0
      @head1 = "OpenFoundry 新聞"
    else
      project_id = params[:project_id]
      @head1 = "專案新聞"
    end
    @news_pages, @news = paginate :news, :conditions => ["catid=?", project_id], :order => "updated_at desc", :per_page => 10
  end
  
  def show
  end
  
  def new
    @news = News.new
  end
  
  def create
    @news = News.new
    @news.subject = params[:news][:subject]
    @news.description = params[:news][:description]
    @news.tags = params[:news][:tags]
    if params[:project_id].nil? 
      project_id = 0
    else
      project_id = params[:project_id]
    end
    @news.catid = project_id
    if @news.save
      flash[:notice] = '新增成功.'
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end
  
  def edit
  end
  
  def update
    if @news.update_attributes(params[:news])
      flash[:notice] = '修改成功.'
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @news.destroy
    redirect_to :action => 'index'
  end

end
