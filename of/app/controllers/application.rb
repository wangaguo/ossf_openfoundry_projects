# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'user_system'
require 'of'
require 'permission_table'
require 'cgi_session_activerecord_store_hack'

# For "paranoid session store"
#require 'action_controller_cgi_request_hack'

class ApplicationController < ActionController::Base
  around_filter :touch_session
  around_filter :set_timezone

  #for permission table
  include OpenFoundry::PermissionTable

  # for ActiveMQ module
  include OpenFoundry::Message
  
  include UserSystem
# for exception growler 
#  include ExceptionGrowler
  
  init_gettext "openfoundry"

  helper :user
  helper :projects
  require_dependency 'user'

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
  protected
  before_init_gettext :set_locale_for_gettext
  # also being invoked when a user changes his/her language preference
  def set_locale_for_gettext!(lang)
    # changing cookies[] only will not have effect in this request
    # cookies["lang"] = params["lang"] = lang
    #
    # lang == 'fr'    is ok
    # lang == 'aaaaa' is ok
    # lang == nil     is still ok !
    # lang == '' will die !!
    #
    # TODO: fall back ?
    # puts "#################### set_locale_for_gettext!: lang: ###{lang}##"
    return if lang == ""
    set_locale(lang, true)
    cookies["lang"] = lang # or set it in the 'after' filter ?
  end

  def set_locale_for_gettext
    lang = ""
    if params["lang"]
      # side-effect: the next page will also render in this language
      #lang = cookies["lang"] = params["lang"]
      lang = params["lang"]
    else
      if cookies["lang"]
        lang = cookies["lang"]
      else
        # TODO: guest / empty language setting
        #set_locale_for_gettext!(current_user.language)
        lang = current_user.language
      end
    end
    set_locale_for_gettext!(lang)
    #set_locale("zh_TW")
  end

  after_init_gettext :set_will_paginate_lang
  def set_will_paginate_lang
    WillPaginate::ViewHelpers.pagination_options[:prev_label] = _("&laquo; Previous")
    WillPaginate::ViewHelpers.pagination_options[:next_label] = _("Next &raquo;")
#    TranslationModel.set_language(GetText.locale.to_s)
  end
  
  #before_filter :login_required
  def current_user(session = session())
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
  #before_filter :touch_session
  #after_filter  :touch_session

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

  #def touch_session
  #  ActionMailer::Base.default_url_options[:host] = request.host_with_port
  #  
  #  # NOTE: I rewrote reset_session in action_controller_cgi_request_hack
  #  return if not ParanoidSqlSessionStore === session
  #  reset_session unless session.host.nil? || session.host == request.remote_ip
  #  session.host ||= request.remote_ip
  #  session.user ||= session[:user_id]
  #end

  #def app_user
  #  @app_user ||= session[:user_id] ? User.find_by_id(session[:user_id]) : nil
  #end

  #def app_user=( u )
  #  session[:user_id] = u.nil? ? nil : u.id
  #  @app_user = u
  #end

  #def session_object
  #  @session_object ||= Session.find_by_session_id session.session_id
  #end

  #def rebuild_session
  #  obj = session_object
  #  reset_session
  #  obj.destroy and obj = nil if obj.host == request.remote_ip unless obj.nil?
  #end

  def self.find_resources(options = { :parent => '', :child => '', :parent_id_method => '', :child_rename => '', :parent_conditions =>  '' })
    child = options[:child].to_s.downcase
    parent = options[:parent].to_s.downcase
    parent_class_name = options[:parent].to_s.camelize
    child_class_name = options[:child].to_s.camelize
    parent_id_method = options[:parent_id_method].to_s || "#{parent}_id"
    parent_conditions = (options[:parent_conditions] || "Project.in_used_projects()").to_s
    if(options[:child_rename].to_s != '')
      child = options[:child_rename].to_s.downcase
    end
    code = <<"THECODE"
    def find_resources_before_filter
      cid = params[:id]
      pid_param = params[:#{parent}_id]
      if cid
        if @#{child} = #{child_class_name}.find_by_id(cid)
          pid_child = @#{child}.#{parent_id_method}   # int
          if pid_child.nil? || pid_child < 1          # lost parent or belongs to site(for news)
            if (pid_param != nil)                     # from url
              flash[:warning] = _("The resource #{child}(\#{cid}) should has no #{parent}.")
              redirect_to :#{parent}_id => nil        # /projects/xx/news/3 => /news/3
            else
              # do nothing.  /news/3 is ok.
            end
          else
            if pid_param != pid_child.to_s            # mismatch !
              flash[:warning] = _("The resource #{child}(\#{cid}) should belong to this #{parent}(\#{pid_child}).")
              redirect_to :#{parent}_id => pid_child, :id => @#{child}.id
            else                                      # good
              if not @#{parent} = #{parent_class_name}.find_by_id(pid_child, :conditions => #{parent_conditions})
                flash[:warning] = "#{parent} '\#{pid_child}' does not exist, or it has be deactivated."
                redirect_to '/'
              else
                # ok !
              end
            end
          end
        else
          flash[:warning] = _("The resource #{child}(\#{cid}) does not exist.")
          # try to fall back to the index page of parent indicated by param
          if @#{parent} = #{parent_class_name}.find_by_id(pid_param, :conditions => #{parent_conditions})
            redirect_to :#{parent}_id => pid_param, :id => nil, :action => 'index'
          else
            redirect_to '/' # TODO: root ?
          end
        end
      elsif pid_param # example: /projects/100/news
        if not @#{parent} = #{parent_class_name}.find_by_id(pid_param, :conditions => #{parent_conditions})
          flash[:warning] = _("The resource #{parent}(\#{pid_param}) does not exist.")
          redirect_to '/' # TODO: root ?
        else
          # do nothing. ok.
        end
      else
        # do nothing.  /news is ok.
      end
    end
    before_filter :find_resources_before_filter
THECODE

    #puts "##############"
    #puts code
    #puts "##############"
    module_eval code
  end
  
  def fpermit?(function_name, authorizable_id, authorizable_type = 'Project')
    Function.function_permit(function_name, authorizable_id, authorizable_type)
  end
  helper_method :fpermit?
  
  def utc_to_local(time)
    begin
      TzTime.zone.adjust(time)
    rescue
      time = ""
    end
  end
  
  def local_to_utc(time)
    begin
      TzTime.zone.unadjust(time)
    rescue
      time
    end
  end
  
  #Overwrite sort_param to include url params
  def sort_param_with_url(sortable_name, *args)
    params.delete(:sortasc)
    params.delete(:sortdesc)
    params.merge(sort_param_without_url(sortable_name, *args))
  end
  alias_method_chain :sort_param, :url
  
  def valid_captcha?
    begin
    match = (params['captcha_code'].downcase == session[:captcha_code].downcase)
    flash[:error] = _('captcha mismatch') unless match
    match
    rescue
      flash[:error] = _('captcha mismatch') 
      false
    end
  end

  def check_permission
    #logger.info("99999999999999999controller: #{controller_name}, action: #{action_name}")
    pass = false
    function_name = PERMISSION_TABLE[controller_name.to_sym][action_name.to_sym]
    begin
      pass =
      if @project
        fpermit?(function_name, @project.id)
      else
        fpermit?(function_name, 0)
      end
    rescue
      pass = false
    ensure
      unless(pass)
        flash[:warning] = _('you have no permission')+" [#{function_name}]!" 
        redirect_to request.referer
      end
    end
    pass
  end

  # see: vendor/plugins/sliding_sessions/ 
  session :session_expires_after => OPENFOUNDRY_SESSION_EXPIRES_AFTER # in seconds
  
  private
    def touch_session
      #logger.info("77777777777777#{session[:host]}77777777777777")
      #logger.info("77777777777777#{request.remote_ip}77777777777777")
      session[:host] = request.remote_ip
      yield
      session[:host] = request.remote_ip
    end
    
    def set_timezone
      if !current_user.timezone.nil?
        TzTime.zone = current_user.tz
      else
        TzTime.zone = TimeZone.new(ENV['TZ'])
      end
      yield
      TzTime.reset!
    end
end
