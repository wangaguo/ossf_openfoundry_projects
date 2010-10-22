class ModulesController < ApplicationController
  def index
    @components = Component.all
  end
  def new
    @component = Component.new
  end
  def create
    component = Component.new(params[:component])
    if component.save 
      redirect_to :action => :index
    end
  end 
end
