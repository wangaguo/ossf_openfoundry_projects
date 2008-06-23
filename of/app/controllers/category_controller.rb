class CategoryController < ApplicationController

  def open
	@category=Category.find params[:id]
  	@contents=Category.find(:all,:conditions => [ "parent=?",params[:id] ] )
	render :layout => false
  end

  def close
	@category=Category.find params[:id]
	render :layout => false
  end

  def index
    list
    render :template => 'category/list'
  end
  
  def list
    projects = Project.find(:all)
#    @maturity = []
#    @license = []
#    @content_license = []
    @platform = []
    @programming_language = []
    @intended_audience = []
    
    projects.each do |p|
#      @maturity |= p.maturity.split(",")
#      @license |= p.license.split(",")
#      @content_license |= p.contentlicense.split(",")
      @platform |= p.platform.split(",")
      @programming_language |= p.programminglanguage.split(",")
      @intended_audience |= p.intendedaudience.split(",")      
    end
  end

  def show
  end

  def edit
  end

  def create
  end

  def destory
  end
end
