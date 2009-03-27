class SiteAdmin < ApplicationController 
  layout "admin"
  before_filter :login_required
  before_filter :check_site_admin

  def check_site_admin
    redirect_to :controller => '../openfoundry' unless( current_user().has_role?('site_admin') or 
                                                      current_user.has_role?('project_reviewer') )
  end
end
