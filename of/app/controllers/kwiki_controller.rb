class KwikiController < ApplicationController
  layout 'module'
  before_filter :get_project
  def get_project
    @project = Project.find(params[:project_id])
    @module_name = "共同筆記"
  end
  
  def index
    @module_url = OPENFOUNDRY_KWIKI_URL + "/" + @project.name + "/index.cgi"
  end
end
