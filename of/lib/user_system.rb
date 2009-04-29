require 'base64'

module UserSystem

  protected
  
  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights  
  # example:
  #
  #  # only allow nonbobs
  #  def authorize?(user)
  #    user.login != "bob"
  #  end
  def authorize?(user)
     true
  end
  
  # overwrite this method if you only want to protect certain actions of the controller
  # example:
  # 
  #  # don't protect the login and the about method
  #  def protect?(action)
  #    if ['action', 'about'].include?(action)
  #       return false
  #    else
  #       return true
  #    end
  #  end
  def protect?(action)
    true
  end
   
  # login_required filter. add 
  #
  #   before_filter :login_required
  #
  # if the controller should be under any rights management. 
  # for finer access control you can overwrite
  #   
  #   def authorize?(user)
  # 
  def login_required
    
    if not protect?(action_name)
      return true  
    end

    if user? and authorize?(session[:user])
      return true
    end

    # store current location so that we can 
    # come back after the user logged in
    store_location
  
    # call overwriteable reaction to unauthorized access
    access_denied #reason
    return false 
  end

  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation. 
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
    flash[:notice] = _('You have to login OpenFoundry first.')
    redirect_to '/user/login'
  end  
  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    session[:return_to] = request.request_uri
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      redirect_to default
    else
      redirect_to session[:return_to]
      session[:return_to] = nil
    end
  end

  def user?
    # First, is the user already authenticated?
    return true if session[:user] and (not params[:s])

    # If not, is the user being authenticated by a token?
    return false if not params[:user]
    id = params[:user]
    if params[:k] and params[:s]
      k,s = params[:k], params[:s]
      atts = Marshal.load(Base64.decode64(s))
      atts = {} unless atts.kind_of? Hash
      #目前只能讓user改 email而已
      atts.delete_if{|k,v| k!=:email} 
      session[:user] = User.authenticate_by_token(id, k, atts)
      return true if not session[:user].nil?
    else
      key = params['key']
      if id and key
        session[:user] = User.authenticate_by_token(id, key)
        return true if not session[:user].nil?
      end
    end
    

    # Everything failed
    return false
  end
end
