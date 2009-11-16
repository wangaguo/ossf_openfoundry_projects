require 'base64'
require 'digest/md5'

class UserController < ApplicationController
  require_dependency  'user'
  before_filter :set_user_id, :except => [:login, :signup, :forgot_password, :welcome, :username_availability_check]
  before_filter :login_required, :except => [:login, :home, :signup, :forgot_password, :welcome, :username_availability_check]

  def set_user_id
    if params['user_alias']
      id = nil
      case params['user_alias']
      when /^\d+$/ 
        id = params['user_alias'] if User.exists?(params['user_alias'])
      when User::LOGIN_REGEX 
        obj = User.find(:first, :select => :id, 
                       :conditions => ["login = ? and #{User.verified_users}", params['user_alias'] ])
        id = obj.id if obj
      end
      if id
        redirect_to "/user/home/#{id}" 
      else
        flash[:warning] = 
          _("User %{user} doesn't exist or be activated") % {:user => params['user_alias']}
        redirect_to "/"
      end
      return
    end
    if params['id']

    end
  end

  def my_projects
    reset_sortable_columns
    add_to_sortable_columns('listing', Project, 'summary', 'summary') 
    add_to_sortable_columns('listing', Project, 'created_at', 'created_at')
    add_to_sortable_columns('listing', Project, 'project_counter', 'project_counter')
    
    # params[:cat] => 'maturity' / 'platform' ...
    # params[:name] => 'beta' / 'windows' ...
    query = "1"
    if params[:cat] =~ /^(maturity|license|contentlicense|platform|programminglanguage)$/
      if params[:cat] != '' && params[:name] != ''
        if params[:cat] !~ /^(maturity)$/
          name = '%,' + params[:name] + ',%'
        else
          name = params[:name]
        end
        query = [params[:cat] + ' like ?', name]
      end
    end
    
    @my_projects = nil
    [params[:page], 1].each do |page|
      @my_projects = Project.paginate_by_sql("
                 select distinct(P.id),P.icon,P.name,P.summary,P.description,
                                       P.created_at,P.updated_at,P.project_counter
                 from projects P join roles R join roles_users RU 
                 where P.id = R.authorizable_id and R.authorizable_type = 'Project' and 
                       P.status = 2 and                      
                       R.id = RU.role_id and RU.user_id = #{current_user.id} order by P.id", 
                                :page => page, :per_page => 10, 
                                :order => sortable_order('listing', :model => Project, 
                                                      :field => 'summary', 
                                                      :sort_direction => :asc) 
                                            )
      break if not @my_projects.out_of_bounds?
    end
  end
  
  def index
    redirect_to :action => :home
  end

  def home
    # given uid to show other user's home
    # or goto login
    # TODO: redirect to login .... ok
    # TODO: user may be empty!!!!!!!!!!!!!!!! .... guest account?
    #logger.info("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!11 #{request.inspect}222222222222")
    
    if params['id']
      user = User.find_by_id params['id']
      @my = ( current_user and (user.id == current_user.id) )
    else
      user = current_user
      @my =true
    end

    if user
      @name = user.login
      @icon = user.icon
      if fpermit?('site_admin', nil) || current_user().has_role?('project_reviewer') then 
        @conceal_homepage = false
        @conceal_email = false
      else
        flash.now[:message] = _("user hide homepage")
        @conceal_homepage = user.t_conceal_homepage
        @conceal_email = user.t_conceal_email
      end
      session[:email_image] = user.email unless @conceal_email
      @email_md5 = Digest::MD5.hexdigest(user.email)
      @created_at = user.created_at
      #@status = user. unless user.t_conseal_status

      @partners = User.find_by_sql("select distinct(U.id),U.icon,U.login from users U join roles_users RU join roles R join roles R2 join roles_users RU2 where U.id = RU.user_id and RU.role_id = R.id and R.authorizable_id = R2.authorizable_id and R.authorizable_type = 'Project' and R2.authorizable_type = 'Project' and RU2.role_id = R2.id and RU2.user_id =#{user.id} and U.id != #{user.id} and #{User.verified_users(:alias => 'U')} order by U.id")
      @projects = Project.find_by_sql("select distinct(P.id),P.icon,P.name from projects P join roles R join roles_users RU where P.id = R.authorizable_id and R.authorizable_type = 'Project' and R.id = RU.role_id and RU.user_id = #{user.id} and #{Project.in_used_projects(:alias => 'P')} order by P.id")
      #@partners = []
      #@projects=user.roles.map{|r| r.name}.uniq.map{|r| user.send("is_#{r}_of_what")}.flatten.uniq
      #@projects.reject!{|p| not ActiveRecord::Base === p}
      #@projects.each do |project|
      #   @partners << project.roles.map{|r| project.send("has_#{r.name}")}.flatten.uniq
      #end
      #@partners.flatten!.uniq!  
    else
      flash[:message] = "You are guest!!"
      redirect_to :action => 'login'
    end
  end

  def username_availability_check
    username = params['username']
    unless username =~ User::LOGIN_REGEX
      render :layout => false, :text => _("Username '%{username}' is invalid") % {:username => username }
      return
    end
    if User.exists?([ "login = ? and #{User.verified_users}", username ])
      render :layout => false, :text => 
      ( _("Username '%{username}' has already registed") % {:username => username } )
    else
      render :layout => false, :text => _("Username '%{username}' is ready for use") % {:username => username }
    end
  end

  def login
    begin redirect_to :action => :home, :controller => :user ;return end if login?

    if params['user'].nil? && !request.referer.nil? then 
      session[:return_to] = request.referer
    end

    # for OpenID Session
    if params['open_id_complete'] and session[:user] = open_id_authentication(nil)
      flash[:message] = _('OpenID Login Succeeded')
      redirect_back_or_default '/user/home' 
      return
    elsif params['use_openid']
      open_id_authentication(params['user']['identity_url'])
      flash[:message] = _('user_login_failed')
      return
    end
    # end of OpenID Session 
    
    return if generate_blank
    #For "paranoid session store"
    #rebuild_session
    
    @user = User.new(params['user'])
    if session[:user] = User.authenticate(params['user']['login'], params['user']['password'])
       
      #Remind user to ENABLE COOKIE!
      if cookies['_of_session_id'].nil?
        @extra_flash = '<p class="flasherror">You must ENABLE cookie to login.</p>'
        render 
        return
      end

      flash[:message] = _('user_login_succeeded')

      # maintain an enumerable hash that includes online users...
      # with a simple lock...
      Session.user_login(session[:user].id)

      redirect_back_or_default :action => :home
      # For "paranoid session store"
      #self.app_user=session[:user]
      
      #      if params['remember_me']
      #        # TODO: is this always the case ??
      #        output_cookies = request.cgi.instance_eval('@output_cookies')
      #        output_cookies[0].expires = Time.now() + OPENFOUNDRY_SESSION_EXPIRES_AFTER # in seconds
      #      end
    else
      flash[:message] = _('user_login_failed')  
    end
  end

  def signup
    #term of use agreement
    return if toua 
    #return if generate_blank
    unless params['user']
      @user = User.new
      return
    end
    params['user'].delete('form')
    user_tags = params['user'].select{|k,v|k =~ /^t_([^=]*)$/}
    params['user'].reject!{|k,v|k =~ /^t_([^=]*)$/}
    @user = User.new(params['user'])
    return unless valid_captcha?
    begin
      User.transaction() do
        @user.icon = Image::IMAGE_DEFAULT_USER_ICON
        @user.new_password = true
        @user.new_email = true
        if @user.save
          #fix rails2.3 ar consist problem
          user_tags.each{|p|@user.method_missing(p[0],p[1])}
          
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
    #logout while su as somebody, and back to site_admin page
    if session[:effective_user]
      session[:effective_user] = nil
      redirect_to '/site_admin'
    else #normal user logout~

      # maintain an enumerable hash that include online users
      # with simple lock
      Session.user_logout(session[:user].id)

      session[:user] = nil
      #For "paranoid session store"
      #kill_login_key
      #rebuild_session

      flash[:message] = _('user_logout_succeeded')
      redirect_to '/'
    end
  end

  def change_email
    return unless login_required #_("you have to login before changing email")
    return if generate_filled_in
    params['user'].delete('form')
    @user.change_email(params[:user][:email], params[:user][:email_confirmation])
    if @user.valid?
      k = @user.generate_security_token()
      s = Base64.encode64(Marshal.dump({:email => @user.email}))
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
    User.transaction do
      @user.change_password(params['user']['old_password'], 
                            params['user']['password'], 
                            params['user']['password_confirmation'])
      begin
        if @user.errors.empty? and @user.save
          UserNotify.deliver_change_password(@user, params['user']['password'])
          flash.now[:notice] = _('user_updated_password') % "#{@user.email}"
        end
      rescue
        flash.now[:warning] = _('user_change_password_email_error')
      end
    end
  end

  def forgot_password
    user = nil
    # Try to send email if logged in
    if user?
      user = current_user
    # Render on :get 
    else
      return if generate_blank
      # Handle the :post
      if params['user']['email'].empty?
        flash.now[:message] = _('user_enter_valid_email_address')
      elsif (user = User.find_by_email(params['user']['email'])).nil?
        flash.now[:message] = _('user_email_address_not_found') % "#{params['user']['email']}"
      end
    end
    
    #send mail for user
    if user
      begin
        User.transaction do
          key = user.generate_security_token
          url = url_for(:action => 'change_password')
          url += "?user=#{user.id}&key=#{key}"
          UserNotify.deliver_forgot_password(user, url)
          flash[:notice] = _('user_forgotten_password_emailed') % "#{params['user']['email']}"
          # use tag to notify forgot password
          user.t_forgot_password = true
          user.save
          unless user?
            redirect_to :action => 'login'
            return
          end
          redirect_back_or_default :action => 'home'
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
          changeable_fields = ['realname', 'language', 'timezone','homepage','bio']
          dummy = params['user'].delete_if { |k,v| not changeable_fields.include?(k) }
          @user.attributes = dummy
          @user.save
          # TODO: refactor
          set_locale_for_gettext!(@user.language)
        when "change_password"
          change_password
        when "change_email"
          change_email
        when "change_privacy"
          changeable_filter = /^t_.*$/
          params['user'].each_pair do |k, v|
            next unless changeable_filter =~ k
            @user.send(k+'=', v)
          end
          @user.save
          flash.now[:notice] = _('Update User Privacy Setting Successed')
        when "delete"
          delete
        else
          raise "unknown edit action"
        end
      end
    end
  end

  def delete
    @user = session[:user]
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
    @user = session[:user]
    @user.deleted = 0
    if not @user.save
      flash.now[:notice] = _('user_restore_deleted_error') % "#{@user['login']}"
      redirect_to :action => 'login'
    else
      redirect_to :action => 'welcome'
    end
  end

  def welcome
    if user? # side-effect ... what the ..
      redirect_to :action => :home
    else
      flash[:error] = _('Sorry, it could be the fellowing reason: User Login Name / Email already be used, Token Expired or Token Not Existed')
      redirect_to '/user/signup'
    end
  end
  
  def search #search for user, use in 'Project Add Member'
    name = params['username']
    limit = params['limit'] || 21
    users = unless name.blank?
      User.find_by_sql(
        ["select id,icon,login,realname,email from users where 
                          #{User.verified_users} and login like  ? limit ?","%#{name}%" ,limit])
    else
      []
    end
    render(:partial => 'search_hit_member',
      :locals => {:users => users},
      :layout => false) 
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
  
  #Generate End User License Agreement for actions on get 
  #and chack agreement for normal process
  def toua
    case request.method
    when :get
      session[:toua] = :show
      render :partial => 'partials/toua', :layout => true, 
        :locals => {:submit_to => '/user/signup', 
                    :file_path => "#{RAILS_ROOT}/public/terms_of_use_agreement.#{GetText.locale.to_s}.txt"}
      return true
    when :post
      if( session[:toua] == :show )
        if( params['agree'] == '1' )
          # eula check ok, normal process
          session[:toua] = :pass
          @user = User.new
          render
          return true
        else
          # eula disagree, back to root
          redirect_to '/'
          return true
        end
      elsif( session[:toua] == :pass )
        #normal process post method!
        return false
      else
        redirect_to '/user/signup'
        return true
      end
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
    @user = current_user
    @user.reload
    case request.method
    when :get
      render
      return true
    end
    return false
  end
  
  def open_id_authentication(identity_url)
    # Pass optional :required and :optional keys to specify what sreg fields you want.
    # Be sure to yield registration, a third argument in the #authenticate_with_open_id block.
    user = nil
    authenticate_with_open_id(identity_url, 
        :required => [:nickname, :email],
        :optional => [:fullname]
         ) do |result, identity_url, registration|
      if result.unsuccessful?
        flash[:error] = result.message
      else 
        user = User.find_or_create_by_identity_url(identity_url)
        if user.new_record?
          assign_registration_attributes!(user, registration)

          unless user.save
            flash[:message] = _("Your OpenID profile registration failed") +': '+
              user.errors.full_messages.to_sentence
            user = nil
          end
        end
      end
      end
    return user
  end
  
  # registration is a hash containing the valid sreg keys given above
  # use this to map them to fields of your user model
  def assign_registration_attributes!(user, registration)
    model_to_registration_mapping.each do |model_attribute, registration_attribute|
      unless registration[registration_attribute].blank?
        user.send("#{model_attribute}=", registration[registration_attribute])
      end
    end
  end

  def model_to_registration_mapping
    { :login => 'nickname', :email => 'email', :realname => 'fullname'}
  end

end
