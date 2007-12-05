class NewsController < ApplicationController 

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
    @news = News.find(params[:id])
  end
  
  def new
    @news = News.new
  end
  
  def create
    #@news = News.new(params[:news])
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
    @news = News.find(params[:id])
  end
  
  def update
    @news = News.find(params[:id])
    if @news.update_attributes(params[:news])
      flash[:notice] = '修改成功.'
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    News.find(params[:id]).destroy
    redirect_to :action => 'index'
  end

end
