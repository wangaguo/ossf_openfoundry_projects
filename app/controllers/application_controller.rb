# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'user_system'
require 'of'
require 'permission_table'
require 'cgi_session_activerecord_store_hack'
require 'hashit'

#require 'gettext_rails'

require 'rubygems'
require 'curb'
# For "paranoid session store"
#require 'action_controller_cgi_request_hack'

# share session cookie for sub-doamins (SSO)
# TODO: substitide domain name in the installing process
#ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_domain] = ".dev.openfoundry.org"

class ApplicationController < ActionController::Base
  #block session store for crawler
  #session :off, :if => lambda {|req| req.user_agent =~ /(Slurp|Spider)/i}

  around_filter :touch_session
  before_filter :set_time_zone
  before_filter :set_locale

  #for permission table
  include OpenFoundry::PermissionTable

  # for ActiveMQ module
  include OpenFoundry::Message
  
  include UserSystem
# for exception growler 
#  include ExceptionGrowler
  
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
  #set locale for each request
  #before_init_gettext :set_gettext_locale
  #after_init_gettext :set_will_paginate_lang
  #init_gettext "openfoundry"
  layout 'normal'

  protected
#  def set_gettext_locale 
    # guest's language should be nil, because "" is true. 
    # request.preferred_language_from is plugin, return value is zh-TW, gettext need zh_TW.
#    cookies[:oflang] = set_locale( (params[:lang] || cookies[:oflang] || current_user.language || request.preferred_language_from(['en', 'zh-TW']) || 'en').gsub('-','_') )
#  end

  # also being invoked when a user changes his/her language preference
#  def set_locale_for_gettext!(lang)
#    cookies[:oflang] = set_locale(lang||"en")
#  end

  def get_project_by_id_or_name(id_or_name)
    rtn = nil
    if fpermit?('site_admin', nil) || current_user().has_role?('project_reviewer') then
      in_used_projects = ""
    else
      in_used_projects = "(#{Project.in_used_projects()} or #{Project.pending_projects()})" #include pending projects for pending status.
    end

    case id_or_name
    when /^\d+$/
      rtn = Project.find_by_id(id_or_name, :conditions => in_used_projects)
    when Project::NAME_REGEX
      in_used_projects = " and #{in_used_projects}" if(in_used_projects != "")
      if rtn = Project.in_used.find(:first, :select => 'id', :conditions => ["name = ? #{in_used_projects}", id_or_name])
        yield rtn.id
        return
      end
    end

    if not rtn or (rtn.status == Project::STATUS[:PENDING] and in_used_projects != "" and (rtn.creator != current_user().id or controller_name != 'projects' or (action_name != 'edit' and action_name != 'update'))) #project not ready. pending and not allow actions.
      flash[:warning] = "Project '#{id_or_name}' does not exist, or it has be deactivated."
      redirect_to root_path
    elsif in_used_projects == "" and rtn.status != Project::STATUS[:READY] #admin & reviewer messages
      flash.now[:warning] = "Project is not READY. Status is #{Project.status_to_s(rtn.status)}."
    end
    rtn
  end

  def set_will_paginate_lang
    WillPaginate::ViewHelpers.pagination_options[:prev_label] = _("&laquo; Previous")
    WillPaginate::ViewHelpers.pagination_options[:next_label] = _("Next &raquo;")
#    TranslationModel.set_language(GetText.locale.to_s)
  end
  
  #before_filter :login_required
  def current_user(session = session() )
    session[:effective_user] || session[:user] || User.find_by_login('guest')
    @current_user = session[:effective_user] || session[:user] || User.find_by_login('guest')
    #effective_user for site_admin 'su' to others 
    #user is your 'normal login user'
  end
  def login?
		login_by_sso
    current_user().login != 'guest' 
  end
  def login_by_sso
    if cookies['ossfauth']
      chk = Curl::Easy.http_post(SSO_FETCH,
                                 Curl::PostField.content('regist_key', SSO_OF_REGIST_KEY),
                                 Curl::PostField.content('session_key', cookies['ossfauth']))

      if chk.body_str != "Error, no such session"
        user_data = Hash[*(chk.body_str.split(/: |, /))]
        session[:user] = User.authenticate_by_sso(user_data['name'])

        # prevent the account is not exist at OF Database only
        # 1) remove the login status here!!
        # 2) record this error!!
        if session[:user].nil?
          cookies.delete :ossfauth
          cookies[:sync_error_at_of] = user_data['name']
        end
			else
				cookies.delete :ossfauth
				session[:user] = nil
      end
    end
  end
  helper_method :current_user
  helper_method :login?

  
  # Pick a unique cookie name to distinguish our session data from others'
  #session :session_key => '_of_session_id'
  
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
                redirect_to root_path
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
            redirect_to root_path
          end
        end
      elsif pid_param # example: /projects/100/news
        if not @#{parent} = #{parent_class_name}.find_by_id(pid_param, :conditions => #{parent_conditions})
          flash[:warning] = _("The resource #{parent}(\#{pid_param}) does not exist.")
          redirect_to root_path
        else
          # do nothing. ok.
        end
      else
        # do nothing.  /news is ok.
      end
    end
    before_filter :find_resources_before_filter
THECODE

    module_eval code
  end
  
  def fpermit?(function_name, authorizable_id, authorizable_type = 'Project')
    Function.function_permit(current_user, function_name, authorizable_id, authorizable_type)
  end
  helper_method :fpermit?
  
  def utc_to_local(time)
    begin
      Time.zone.utc_to_local(time)
    rescue
      time = ""
    end
  end
  
  def local_to_utc(time)
    begin
      Time.zone.local_to_utc(time.to_time)
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
    rescue Exception => e
      pass = false
    ensure
      unless(pass)
        flash[:warning] = _('you have no permission')#+" [#{function_name} #{e}]!" 
        redirect_to(request.referer || root_path)
      end
    end
    pass
  end

  protected
  def check_download_consistancy
    #this method will check PROJECT NAME, RELEASE VERSION, FILE PATH, and their associations
    #include PROJECT STATUS and RELEASE STATUS
    #WON'T consider user's PERMISSION nor LOGIN

    project_name = params["project_name"]
    release_version = params["release_version"]
    file_name = params["file_name"]

    @project = Project.find_by_name( 
             project_name, :include => [:releases], 
                           :conditions => Project.in_used_projects )
    @release = @project.releases.find_by_version( 
             release_version, :include => [:fileentity],
                              :conditions => Release.published_releases(:alias => 'releases') ) if @project
    @file = @release.fileentity.find_by_path( 
             file_name, :include => [:survey],
                        :conditions => Fileentity.published_files(:alias => 'fileentities') ) if @release

    @error_msg ||= ''

    @error_msg += ("The project \"#{project_name}\" you are requesting does not exist.") unless @project
#%
#           {:project => CGI.escapeHTML(project_name)} unless @project
    @error_msg += ("The release \"#{release_version}\" you are requesting does not exist.") unless @release #%
  # {:release => CGI.escapeHTML(release_version)} unless @release
    @error_msg += ("The file \"#{file_name}\" you are requesting does not exist.") unless @file #%
 #  {:file_name => CGI.escapeHTML(file_name)} unless @file
  end


  private
    def touch_session
      session[:host] = request.remote_ip
      yield
      session[:host] = request.remote_ip
    end

    def set_time_zone
      if !current_user.timezone.nil?
        Time.zone = current_user.timezone
      end
    end

    def s_(key)
      I18n.t key
    end
    helper_method :s_
    def _(key)
      I18n.t key
    end
    helper_method :_

  #####################
  # locale setting
  #####################
  def set_locale
    #what language we support
    @locales = {:en => 'English', :zh_TW => '繁體中文'}

    #this is our language selection priority:
    locale = ( params[:lang] || cookies[:oflang] || session[:lang] || scan_lang_from_browser || scan_lang_from_user || :zh_TW )
    locale = locale[0] if Array === locale
    locale = :zh_TW if locale == ''
    #lang is not supported, use :zh_TW
    locale = :zh_TW unless(@locales.has_key? locale.to_sym)

    #set lang to session, cookie, and I18n
    I18n.locale = session[:lang] = cookies[:oflang] = locale
  end

  def scan_lang_from_browser
    ( request.env['HTTP_ACCEPT_LANGUAGE'] || '' ).scan(/^[a-z]{2}/).first
  end

  def scan_lang_from_user
    session[:user].lang if session[:user]
  end

end
