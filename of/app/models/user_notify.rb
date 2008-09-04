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

  def setup_email(user)
    @recipients = "#{user.email}"
    @from       = UserSystem::CONFIG[:email_from].to_s
    @subject    = "[#{UserSystem::CONFIG[:app_name]}] "
    @sent_on    = Time.now
    #@headers['Content-Type'] = "text/html; charset=#{UserSystem::CONFIG[:mail_charset]}; format=flowed"
    content_type "text/html"
  end
end