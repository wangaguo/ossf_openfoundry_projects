class UserNotify < ActionMailer::Base
  def signup(user, password, url=nil)
    setup_email(user)
    
    # Email header info
    @subject += "Welcome to #{UserSystem::CONFIG[:app_name]}!"
     
    # Email body substitutions
    @body["name"] = "#{user.realname}"
    @body["login"] = user.login
    @body["password"] = password
    @body["url"] = url || UserSystem::CONFIG[:app_url].to_s
    @body["app_name"] = UserSystem::CONFIG[:app_name].to_s
  end

  def forgot_password(user, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Forgotten password notification"

    # Email body substitutions
    @body["name"] = "#{user.realname}"
    @body["login"] = user.login
    @body["url"] = url || UserSystem::CONFIG[:app_url].to_s
    @body["app_name"] = UserSystem::CONFIG[:app_name].to_s
  end

  def change_email(dummyuser, url)
    setup_email(dummyuser)

    # Email header info
    @subject += "Changed email notification"

    # Email body substitutions
    @body["url"] = url || UserSystem::CONFIG[:app_url].to_s
    @body["app_name"] = UserSystem::CONFIG[:app_name].to_s
  end  
  
  def change_password(user, password, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Changed password notification"

    # Email body substitutions
    @body["name"] = "#{user.realname}"
    @body["login"] = user.login
    @body["password"] = password
    @body["url"] = url || UserSystem::CONFIG[:app_url].to_s
    @body["app_name"] = UserSystem::CONFIG[:app_name].to_s
  end

  def pending_delete(user, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Delete user notification"

    # Email body substitutions
    @body["name"] = "#{user.realname}"
    @body["url"] = url || UserSystem::CONFIG[:app_url].to_s
    @body["app_name"] = UserSystem::CONFIG[:app_name].to_s
    @body["days"] = UserSystem::CONFIG[:delayed_delete_days].to_s
  end

  def delete(user, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Delete user notification"

    # Email body substitutions
    @body["name"] = "#{user.realname}"
    @body["url"] = url || UserSystem::CONFIG[:app_url].to_s
    @body["app_name"] = UserSystem::CONFIG[:app_name].to_s
  end
 
  def site_mail(user, subject, message)
    setup_email(user)
    @subject = subject
    @body["message"] = message
  end

  def setup_email(user)
    @recipients = "#{user.email}"
    @from       = UserSystem::CONFIG[:email_from].to_s
    @subject    = "[#{UserSystem::CONFIG[:app_name]}] "
    @sent_on    = Time.now
  end
  
  def build_user_email(assigns)
    part("multipart/alternative") do |p|
      UserSystem::CONFIG[:available_content_type].each do |content_type|
      p.part:content_type => content_type,
             :body => 
             render_message("#{@template}.#{content_type.sub(/\//, '.')}.rhtml", assigns) 
      end
    end
  end
  
  def rm_render_message(method_name, body)
    layout = method_name.match(%r{text\.html\.rhtml}) ? 'layout.text.html.rhtml' : 'layout.text.plain.rhtml'
    body[:content_for_layout] = render(:file => method_name, :body => body)
    ActionView::Base.new(template_root, body, self).render(:file => "#{RAILS_ROOT}/app/views/user_notify/#{layout}")
  end
end
