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
    @module_name = _('Project Category')
    #projects = Project.find(:all, :conditions => Project::in_used_projects())
    @maturity = {}
    @license = {}
    @content_license = {}
    @platform = {}
    @programming_language = {}
    
    Project.in_used.each do |p|
      [p.maturity].each{|x| @maturity[x] = (@maturity[x] || 0) + 1}
      "#{p.license}".split(",").grep(/./).each{|x| @license[x] = (@license[x] || 0) + 1}
      "#{p.contentlicense}".split(",").grep(/./).each{|x| @content_license[x] = (@content_license[x] || 0) + 1}
      "#{p.platform}".split(",").grep(/./).each{|x| @platform[x] = (@platform[x] || 0) + 1}
      "#{p.programminglanguage}".split(",").grep(/./).each{|x| @programming_language[x] = (@programming_language[x] || 0) + 1}
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
