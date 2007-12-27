# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'user_system'
# For "paranoid session store"
require 'action_controller_cgi_request_hack'

class ApplicationController < ActionController::Base
  include UserSystem
# for exception growler 
#  include ExceptionGrowler
  
  init_gettext "openfoundry"

  helper :user
  model  :user

#  before_filter :configure_charsets
#
#  def configure_charsets
#    @response.headers["Content-Type"] = "text/html; charset=utf-8"
#    # Set connection charset. MySQL 4.0 doesn't support this so it
#    # will throw an error, MySQL 4.1 needs this
#        suppress(ActiveRecord::StatementInvalid) do
#          ActiveRecord::Base.connection.execute 'SET NAMES UTF8'
#        end
#  end
  before_init_gettext :set_locale_for_gettext
  
  def set_locale_for_gettext!(lang)
    # changing cookies[] only will not have effect in this request
    # cookies["lang"] = params["lang"] = lang
    set_locale(lang, true)
  end

  def set_locale_for_gettext
    if params["lang"]
      cookies["lang"] = params["lang"]
    else
      if cookies["lang"]
      else
        # TODO: guest / empty language setting
        set_locale_for_gettext!(current_user.language)
      end
    end
    #set_locale("zh_TW")
  end

  #before_filter :login_required
  def current_user
    session['user'] || User.find_by_login('guest') # TODO: fix it !!!!!
  end
  def login?
    current_user().login != 'guest' 
  end
  helper_method :current_user
  helper_method :login?

  
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_of_session_id'
  
  # Fro "paranoid session store"
  before_filter :touch_session
  after_filter  :touch_session

  def add_tag
	  type=params['class']
	  id=params['id']
	  obj=Object.const_get(type).find(id)
	  obj.tag_list.add(params['tag'])
	  obj.save
	  redirect_to :back 
  end

  def remove_tag
	  type=params['class']
	  id=params['id']
	  obj=Object.const_get(type).find(id)
	  obj.tag_list.remove(params['tag'])
	  obj.save
	  redirect_to :back
  end

  before_filter :set_host_for_action_mailer
  def set_host_for_action_mailer
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end

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

  def self.find_resources(options = {:parent => '', :child => '', :parent_id_method => ''})
    child = options[:child].to_s.downcase
    parent = options[:parent].to_s.downcase
    parent_class_name = options[:parent].to_s.camelize
    child_class_name = options[:child].to_s.camelize
    parent_id_method = options[:parent_id_method].to_s
    code = <<"THECODE"
    def find_resources_before_filter
      if params[:id] != nil
        begin
          @#{child} = #{child_class_name}.find(params[:id])
          if @#{child}.#{parent_id_method}.nil? || @#{child}.#{parent_id_method} < 1
            if (params[:#{parent}_id] != nil)
              redirect_to :#{parent}_id => nil
            end
          else
            if params[:#{parent}_id] != @#{child}.#{parent_id_method}.to_s
              redirect_to :#{parent}_id => @#{child}.#{parent_id_method}, :id => @#{child}.id
            else
              @#{parent} = #{parent_class_name}.find(@#{child}.#{parent_id_method})
            end
          end
        rescue
          begin
            @#{parent} = #{parent_class_name}.find(params[:#{parent}_id])
            redirect_to :#{parent}_id => @#{parent}.id, :id => nil, :action => 'index'
          rescue
            redirect_to '/' # TODO: root ?
          end
        end
      elsif params[:#{parent}_id] != nil
        begin
          @#{parent} = #{parent_class_name}.find(params[:#{parent}_id])
        rescue
          redirect_to '/' # TODO: root ?
        end
      end
    end
    before_filter :find_resources_before_filter
THECODE

    #puts "##############"
    #puts code
    #puts "##############"
    module_eval code
  end

  
end
