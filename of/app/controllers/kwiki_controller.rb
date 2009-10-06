class KwikiController < ApplicationController
  layout 'module'
  before_filter :get_project
  def get_project
    @project = get_project_by_id_or_name(params[:project_id]) { |id| redirect_to :project_id => id }
    @module_name = _('Wiki')
  end
  
  def index
    # note: be aware of "/"
    @module_url = OPENFOUNDRY_KWIKI_URL + @project.name + "/index.cgi"
  end
end
