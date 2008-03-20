class RtController < ApplicationController
  before_filter :get_project
  def get_project
    @project = Project.find(params[:project_id])
  end
  
  def index
    get_project
    @rt_url = "http://rt.of.openfoundry.org"
    @queue_url = @rt_url + "/Search/Results.html?Order=DESC&OrderBy=LastUpdated&Query=Queue = '" + @project.unixname + "'"
    @queue_type_url = @queue_url + " AND 'CF.{Type}' LIKE '@type'"
  end
end
