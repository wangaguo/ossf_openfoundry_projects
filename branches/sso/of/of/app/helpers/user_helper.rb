module UserHelper

  def role_portrait(role, _options = {})
    options = {
      :size => 32,
      :float => nil,
    }.merge(_options)

    title = role.respond_to?('p_name') ? "#{role.p_name}'s #{role.name}" : role.name

    "<div class=\"role_portrait\" title=\"#{title}\">
     <img src=\"/images/cached_image/1_#{options[:size]}\"  
                         align=#{options[:align]||:middle} />
     <br/> #{title}
     </div>"
  end
  def user_portrait_link(user, _options = {})
    options = {
      :size => 32,
      :with_login => false,
      :float => nil,
      :link => "/community/userprofile/#{user.login}" 
    }.merge(_options)
    rdf_tag = options[:rdf_tag] || ''
    "<div class=\"user_portrait\" title=\"#{user.login}\" 
    style=\"#{options[:float] ? "float:#{options[:float]};" : 'display:inline;'} 
    height:#{options[:with_login] ? '55' : '32' }px; 
    width:#{options[:with_login] ? '60' : '32' }px; 
    border:dotted 1px #eee; text-align:center; vertical-align:text-bottom; line-height: normal;  
    white-space:normal; word-break:break-all; overflow:hidden;\">
    #{options[:link]? "<a #{rdf_tag} href=\"#{options[:link]}\">" : '' }
     <img src=\"http://#{SSO_HOST}/sso/user/image?name=#{user.login}&amp;size=medium\"
      align=\"#{options[:align]||:middle}\" />
     #{options[:with_login] ? "<br/> #{user.login}" : '' }
    #{options[:link]? "</a>":'' }
    </div>"
  end

  SSO_URL = 'http://ssodev.openfoundry.org/sso/user/'
  def sso_login_url
    SSO_URL+'login'
  end
  def sso_logout_url
    SSO_URL+'logout'
  end
  def sso_signup_url
    SSO_URL+'signup'
  end
end
