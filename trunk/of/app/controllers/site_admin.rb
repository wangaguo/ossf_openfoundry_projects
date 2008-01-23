class SiteAdmin < ApplicationController 
  layout "admin"
  before_filter :check_site_admin

  def check_site_admin
    redirect_to :controller => '../openfoundry' if not current_user().has_role?('site_admin')
  end
end
