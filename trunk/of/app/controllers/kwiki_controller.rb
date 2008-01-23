class KwikiController < ApplicationController
  before_filter :get_project
  def get_project
    @project = Project.find(params[:project_id])
  end
  
  def index
    render 'kwiki/kwiki'
  end
end
