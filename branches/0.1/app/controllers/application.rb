# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'localization'
require 'user_system'
# For "paranoid session store"
require 'action_controller_cgi_request_hack'

class ApplicationController < ActionController::Base
  include Localization
  include UserSystem

  init_gettext "openfoundry"

  helper :user
  model  :user

  before_filter :configure_charsets

  def configure_charsets
    @response.headers["Content-Type"] = "text/html; charset=utf-8"
    # Set connection charset. MySQL 4.0 doesn't support this so it
    # will throw an error, MySQL 4.1 needs this
        suppress(ActiveRecord::StatementInvalid) do
          ActiveRecord::Base.connection.execute 'SET NAMES UTF8'
        end
  end

  #before_filter :login_required
  def current_user
    session['user']
  end
  def login?
    not current_user().nil? # !!
  end
  helper_method :current_user
  helper_method :login?

  
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_of_session_id'
  
  # Fro "paranoid session store"
  before_filter :touch_session
  after_filter  :touch_session


  protected
  def touch_session
    # NOTE: I rewrote reset_session in action_controller_cgi_request_hack
    reset_session unless session.host.nil? || session.host == request.remote_ip
    session.host ||= request.remote_ip
    session.user ||= session[:user_id]
  end

  def app_user
    @app_user ||= session[:user_id] ? User.find_by_id(session[:user_id]) : nil
  end

  def app_user=( u )
    session[:user_id] = u.nil? ? nil : u.id
    @app_user = u
  end

  def session_object
    @session_object ||= Session.find_by_session_id session.session_id
  end

  def rebuild_session
    obj = session_object
    reset_session
    obj.destroy and obj = nil if obj.host == request.remote_ip unless obj.nil?
  end

end
