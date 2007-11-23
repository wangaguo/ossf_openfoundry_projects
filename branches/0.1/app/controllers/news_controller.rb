class NewsController < ApplicationController 
  def index
    list
    render :action => 'list'
#    rend
  end
  
  def item
  end
   
  def _home_news
    #@news = News.home_news
    render :partial => "home_news", :locals => {:newsList => News.home_news}
    #render :layout => false
  end
  
  def news_list
    @news_pages, @news = paginate :news, :conditions => "catid=0", :order => "'update_at'", :per_page => 10
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :action => :list }
  
  def list
    @news_pages, @news = paginate :news, :per_page => 10
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
    @news.catid = params[:news][:catid]
    @news.create_at = DateTime.now
    @news.update_at = DateTime.now
    if @news.save
      flash[:notice] = 'News was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end
  
  def edit
    @news = News.find(params[:id])
  end
  
  def update
    @news = News.find(params[:id])
    params[:news][:update_at] = DateTime.now
    if @news.update_attributes(params[:news])
      flash[:notice] = 'News was successfully updated.'
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    News.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
