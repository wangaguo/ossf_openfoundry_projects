# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'localization'
require 'user_system'

class ApplicationController < ActionController::Base
  include Localization
  include UserSystem

  helper :user
  model  :user

  before_filter :login_required

  
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_of_session_id'
end
