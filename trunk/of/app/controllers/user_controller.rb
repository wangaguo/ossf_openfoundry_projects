require 'base64'

class UserController < ApplicationController
  require_dependency  'user'
  before_filter :login_required, :except => [:login, :signup, :forgot_password, :welcome]

  def online_users
    @online_users=User.online_users
    @online_guests=Session.anonymous_sessions
  end
  def home
    # TODO: redirect to login .... ok
    # TODO: user may be empty!!!!!!!!!!!!!!!! .... guest account?
    #logger.info("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11 #{request.inspect}222222222222")
    if user = session['user']
      @my_partners = []
      @my_projects = user.roles.map{|r| r.name}.uniq.map{|r| user.send("is_#{r}_of_what")}.flatten.uniq
      @my_projects.reject!{|p| not p === ActiveRecord::Base}
      @my_projects.each do |project|
         @my_partners << project.roles.map{|r| project.send("has_#{r.name}")}.flatten.uniq
      end
      @my_partners.flatten!.uniq!  
    else
      flash[:message] = "You are guest!!"
      redirect_to :action => 'login'
    end
  end


  def login
    begin redirect_to :action => :home, :controller => :user ;return end if login?
    return if generate_blank
    #For "paranoid session store"
    #rebuild_session

    @user = User.new(params['user'])
    if session['user'] = User.authenticate(params['user']['login'], params['user']['password'])
      flash[:message] = _('user_login_succeeded')
      redirect_back_or_default :action => :home
      # For "paranoid session store"
      #self.app_user=session['user']

      if params['remember_me']
        # TODO: is this always the case ??
        output_cookies = request.cgi.instance_eval('@output_cookies')
        output_cookies[0].expires = Time.now() + OPENFOUNDRY_SESSION_EXPIRES_AFTER # in seconds
      end
    else
      @login = params['user']['login']
      flash.now[:message] = _('user_login_failed')
    end
  end

  def signup
    return if generate_blank
    params['user'].delete('form')
    @user = User.new(params['user'])
    begin
      User.transaction() do
        @user.new_password = true
        if @user.save
          key = @user.generate_security_token
          url = url_for(:action => 'welcome')
          url += "?user=#{@user.id}&key=#{key}"
          UserNotify.deliver_signup(@user, params['user']['password'], url)
          flash[:notice] = _('user_signup_succeeded')
          redirect_to :action => 'login'
        end
      end
    rescue
      flash.now[:message] = _('user_confirmation_email_error')
    end
  end  
   
  def logout
    session['user'] = nil
    #For "paranoid session store"
    #kill_login_key
    #rebuild_session

    redirect_to :action => 'login'
  end

  def change_email
    return unless login_required #_("you have to login before changing email")
    return if generate_filled_in
    params['user'].delete('form')
    @user.change_email(params[:user][:email], params[:user][:email_confirmation])
    if @user.valid?
      k = @user.generate_security_token()
      s = Base64.encode64(Marshal.dump(@user.email))
      url = url_for(:action => :welcome)
      url+= "?user=#{@user.id}&k=#{k}&s=#{s}"
      UserNotify.deliver_change_email(@user, url)
      flash.now[:notice] = _('user_updated_email') % "#{@user.email}"
    else
      flash.now[:warning] = _('user_change_email_error')
    end
    #dummy = User.find_by_login('dummy')
#    begin
#      #User.transaction(@user) do
#        #dummy.change_email(params[:user][:email], params[:user][:email_confirmation])
#        if @user.save and dummy.save
#          k = @user.generate_security_token()
#          s = Base64.encode64(Marshal.dump(dummy.email))
#          url = url_for(:action => :welcome)
#          url+= "?user[id]=#{@user.id}&k=#{k}&s=#{s}"
#          UserNotify.deliver_change_email(dummy, url)
#          flash[:notice] = _('user_updated_email') % "#{dummy.email}"
#        end
#      end
#    rescue
#      @user.errors = dummy.errors
#      flash[:warning] = _('user_change_email_error')
#    end
  end
  
  def change_password
    return unless login_required #_("you have to login before changing password")
    return if generate_filled_in
    params['user'].delete('form')
    begin
      User.transaction do
        @user.change_password(params['user']['password'], params['user']['password_confirmation'])
        if @user.save
          UserNotify.deliver_change_password(@user, params['user']['password'])
          flash.now[:notice] = _('user_updated_password') % "#{@user.email}"
        end
      end
    rescue
      flash.now[:warning] = _('user_change_password_email_error')
    end
  end

  def forgot_password
    # Always redirect if logged in
    if user?
      flash[:message] = _('user_forgot_password_logged_in')
      redirect_to :action => 'change_password'
      return
    end

    # Render on :get and render
    return if generate_blank

    # Handle the :post
    if params['user']['email'].empty?
      flash.now[:message] = _('user_enter_valid_email_address')
    elsif (user = User.find_by_email(params['user']['email'])).nil?
      flash.now[:message] = _('user_email_address_not_found') % "#{params['user']['email']}"
    else
      begin
        User.transaction do
          key = user.generate_security_token
          url = url_for(:action => 'change_password')
          url += "?user=#{user.id}&key=#{key}"
          UserNotify.deliver_forgot_password(user, url)
          flash[:notice] = _('user_forgotten_password_emailed') % "#{params['user']['email']}"
          unless user?
            redirect_to :action => 'login'
            return
          end
          redirect_back_or_default :action => 'welcome'
        end
      rescue
        flash.now[:message] = _('user_forgotten_password_email_error') % "#{params['user']['email']}"
      end
    end
  end

  def edit
    return unless login_required #_("you have to login before editing user")
    return if generate_filled_in
    if params['user']['form']
      form = params['user'].delete('form')
      begin
        case form
        when "edit"
          changeable_fields = ['firstname', 'lastname', 'language', 'timezone']
          dummy = params['user'].delete_if { |k,v| not changeable_fields.include?(k) }
          @user.attributes = dummy
          @user.save
          # TODO: refactor
          set_locale_for_gettext!(@user.language)
        when "change_password"
          change_password
        when "change_email"
          change_email
        when "delete"
          delete
        else
          raise "unknown edit action"
        end
      end
    end
  end

  def delete
    @user = session['user']
    begin
      if UserSystem::CONFIG[:delayed_delete]
        User.transaction(@user) do
          key = @user.set_delete_after
          url = url_for(:action => 'restore_deleted')
          url += "?user=#{@user.id}&key=#{key}"
          UserNotify.deliver_pending_delete(@user, url)
        end
      else
        destroy(@user)
      end
      logout
    rescue
      flash.now[:message] = _('user_delete_email_error') % "#{@user['email']}"
      redirect_back_or_default :action => 'welcome'
    end
  end

  def restore_deleted
    @user = session['user']
    @user.deleted = 0
    if not @user.save
      flash.now[:notice] = _('user_restore_deleted_error') % "#{@user['login']}"
      redirect_to :action => 'login'
    else
      redirect_to :action => 'welcome'
    end
  end

  def welcome
    user? # side-effect ... what the ..
  end

  protected

  def destroy(user)
    UserNotify.deliver_delete(user)
    flash[:notice] = _('user_delete_finished') % "#{user['login']}"
    user.destroy()
  end

  def protect?(action)
    if ['login', 'signup', 'forgot_password'].include?(action)
      return false
    else
      return true
    end
  end

  # Generate a template user for certain actions on get
  def generate_blank
    case request.method
    when :get
      @user = User.new
      render
      return true
    end
    return false
  end

  # Generate a template user for certain actions on get
  def generate_filled_in
    @user = session['user']
    @user.reload
    case request.method
    when :get
      render
      return true
    end
    return false
  end
end
