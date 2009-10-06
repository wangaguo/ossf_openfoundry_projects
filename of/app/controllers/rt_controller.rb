class RtController < ApplicationController
  layout 'rt'
  before_filter :get_project
  def get_project
    @project = get_project_by_id_or_name(params[:project_id]) { |id| redirect_to :project_id => id }
  end

  def index
    rt_init
  end
  
  def show
    rt_init
    render :action => 'index'
  end

  def rt_init
    if login? == false
      flash[:warning] = _("You have not logged in; please log in or register from the links in the top-left corner. If you really want to submit a ticket as guest, please leave your contact information, such as email address, in the ticket body, so the developers can contact you when the issue is resolved. ")
    end
    @rt_url = OPENFOUNDRY_RT_URL
    @base_url = @rt_url + "Search/Results.html?" + 
      "Format=%27%20%20%20%3Cb%3E%3Ca%20href%3D%22%2Frt%2FTicket%2FDisplay.html%3Fid%3D__id__%22%3E__id__%3C%2Fa%3E%3C%2Fb%3E%2FTITLE%3A%23%27%2C%0A%27%3Cb%3E%3Ca%20href%3D%22%2Frt%2FTicket%2FDisplay.html%3Fid%3D__id__%22%3E__Subject__%3C%2Fa%3E%3C%2Fb%3E%2FTITLE%3ASubject%27%2C" +
      "'__Status__'," \
      "'__QueueName__'," \
      "'__OwnerName__'," \
      "'__NEWLINE__'," \
      "'<small>__CustomField.{Severity}__</small>'," \
      "'<small>__Requestors__</small>'," \
      "'<small>__CreatedRelative__</small>'," \
      "'<small>__ToldRelative__</small>'," \
      "'<small>__LastUpdatedRelative__</small>'" \
      "&Order=DESC&OrderBy=LastUpdated&Query="
    if(@project != nil)
      @base_url += "Queue = '" + @project.id.to_s + "'"
    else
      @base_url += "id>'0'"
    end
    if(params[:id] != nil)
      if((params[:id] =~ /^\d*$/) == 0)
        @show_url = @rt_url + "Ticket/Display.html?id=" + params[:id]
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
          @base_url += " AND 'CF.{Type}' LIKE '" + params[:id] + "'"
        end
        @show_url = @base_url
      end
    else
      @show_url = @base_url;
    end
    @tabnav_url = @base_url + " AND 'CF.{Type}' LIKE '@type'"
  end
end
