class SiteAdmin < ApplicationController 
  layout "admin"
  before_filter :login_required
  before_filter :check_site_admin

  def check_site_admin
    redirect_to :controller => '../of/openfoundry' unless( 
                  current_user().has_role?('site_admin') or 
                  current_user().has_role?('project_reviewer') or 
                  current_user().has_role?('content_admin') )
  end
end
