class CategoryController < ApplicationController
  layout "streamlined"
    acts_as_streamlined
  def open
	@category=Category.find params[:id]
  	@contents=Category.find(:all,:conditions => [ "parent=?",params[:id] ] )
	render :layout => false
  end

  def close
	@category=Category.find params[:id]
	render :layout => false
  end
end
