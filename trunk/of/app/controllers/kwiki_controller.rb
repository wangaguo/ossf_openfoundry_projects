class KwikiController < ApplicationController
  before_filter :get_project
  def get_project
    @project = Project.find(params[:project_id])
  end
  
  def index
    @module_url = OPENFOUNDRY_KWIKI_URL + "/" + @project.name + "/index.cgi"
  end
end
