class RtController < ApplicationController
  before_filter :get_project
  def get_project
    @project = Project.find(params[:project_id])
  end
  
  def index
    rt_init
  end
  
  def show
    rt_init
    render :action => 'index'
  end

  def rt_init
    @rt_url = OPENFOUNDRY_RT_URL
    if(params[:id] == nil)
      @queue_url = @rt_url + "/Search/Results.html?Order=DESC&OrderBy=LastUpdated&Query=Queue = '" + @project.unixname + "'"
    else
      #puts ((params[:id] =~ /^\d*$/).to_s+"!!")
      if((params[:id] =~ /^\d*$/) == 0)
        @queue_url = @rt_url + "/Ticket/Display.html?id=" + params[:id]
      else
        @queue_url = @rt_url + "/Search/Results.html?Order=DESC&OrderBy=LastUpdated&Query=Queue = '" + @project.unixname + "'" + " AND 'CF.{Type}' LIKE '" + params[:id] + "'"
      end
    end
    @queue_type_url = @queue_url + " AND 'CF.{Type}' LIKE '@type'"
  end
end