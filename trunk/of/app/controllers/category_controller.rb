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

  def show
  end

  def edit
  end

  def create
  end

  def destory
  end
end
