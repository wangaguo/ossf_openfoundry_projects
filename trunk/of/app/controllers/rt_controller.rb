class RtController < ApplicationController
  before_filter :get_project
  def get_project
    if(params[:project_id] != nil)
      @project = Project.find(params[:project_id])
    end
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
    @base_url = @rt_url + "/Search/Results.html?Order=DESC&OrderBy=LastUpdated&Query="
    if(@project != nil)
      @base_url += "Queue = '" + @project.unixname + "'"
    else
      @base_url += "id>'0'"
    end
    if(params[:id] != nil)
      if((params[:id] =~ /^\d*$/) == 0)
        @show_url = @rt_url + "/Ticket/Display.html?id=" + params[:id]
      else
        if(params[:id] == 'owner')
          @base_url += " AND Owner='" + current_user.login + "'"
        elsif(params[:id] == 'creator')
          @base_url += " AND Creator='" + current_user.login + "'"
        elsif(params[:id] == 'Requestor'.downcase)
          @base_url += " AND Requestor.Name='" + current_user.login + "'"
        elsif(params[:id] == 'LastUpdatedBy'.downcase)
          @base_url += " AND LastUpdatedBy='" + current_user.login + "'"
        else
          @show_url = @base_url + " AND 'CF.{Type}' LIKE '" + params[:id] + "'"
        end
      end
    else
      @show_url = @base_url;
    end
    @tabnav_url = @base_url + " AND 'CF.{Type}' LIKE '@type'"
  end
end