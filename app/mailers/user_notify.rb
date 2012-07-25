class UserNotify < ActionMailer::Base
  default :from => UserSystem::CONFIG[:email_from].to_s
  layout 'user_notify'

  def signup(user, password, url=nil)
    # Set Content-Type for Sending mails
    #@content_type = "text/html"
    @user = user
     
    # Email body substitutions
    @password = password
    @url = url || UserSystem::CONFIG[:app_url].to_s
    @app_name = UserSystem::CONFIG[:app_name].to_s

    mail(:to => @user.email,
         :subject => subject_with_head("Welcome to #{UserSystem::CONFIG[:app_name]}!"))
  end

  def forgot_password(user, url=nil)
    # Set Content-Type for Sending mails
    #@content_type = "text/html"

    # Email header info
    @subject += "Forgotten password notification"

    # Email body substitutions
    @name = user.realname
    @login = user.login
    @url = url || UserSystem::CONFIG[:app_url].to_s
    @app_name = UserSystem::CONFIG[:app_name].to_s
    mail(:to => @user.email,
         :subject => subject_with_head("Forgotten password notification"))
  end

  def change_email(dummyuser, url)
    setup_email(dummyuser)

    # Set Content-Type for Sending mails
    @content_type = "text/html"

    # Email header info
    @subject += "Changed email notification"

    # Email body substitutions
    @url = url || UserSystem::CONFIG[:app_url].to_s
    @app_name = UserSystem::CONFIG[:app_name].to_s
  end  
  
  def change_password(user, password, url=nil)
    setup_email(user)

    # Set Content-Type for Sending mails
    @content_type = "text/html"

    # Email header info
    @subject += "Changed password notification"

    # Email body substitutions
    @name = "#{user.realname}"
    @login = user.login
    @password = password
    @url = url || UserSystem::CONFIG[:app_url].to_s
    @app_name = UserSystem::CONFIG[:app_name].to_s
  end

  def pending_delete(user, url=nil)
    setup_email(user)

    # Set Content-Type for Sending mails
    @content_type = "text/html"

    # Email header info
    @subject += "Delete user notification"

    # Email body substitutions
    @name = "#{user.realname}"
    @url = url || UserSystem::CONFIG[:app_url].to_s
    @app_name = UserSystem::CONFIG[:app_name].to_s
    @days = UserSystem::CONFIG[:delayed_delete_days].to_s
  end

  def delete(user, url=nil)
    setup_email(user)

    # Set Content-Type for Sending mails
    @content_type = "text/html"

    # Email header info
    @subject += "Delete user notification"

    # Email body substitutions
    @name = "#{user.realname}"
    @url = url || UserSystem::CONFIG[:app_url].to_s
    @app_name = UserSystem::CONFIG[:app_name].to_s
  end
 
  def site_mail(subject, message)
    @from    = "OSSF Contact<#{UserSystem::CONFIG[:email_from].to_s}>"
    @sent_on = Time.now
    @subject = subject
    @message = message
    @content_type = "text/html"
  end

  # Unused
#  def test(user)
#    setup_user_email(user) 
#    @subject += 'Test by Tim!'
#    assigns = {}
#    assigns["name"] = "#{user.realname}"
#    assigns["login"] = user.login
#    assigns["password"] = 1234
#    assigns["url"] = UserSystem::CONFIG[:app_url].to_s
#    assigns["app_name"] = UserSystem::CONFIG[:app_name].to_s
#    build_user_email(assigns)
#  end

  def setup_email(user)
    @recipients = "#{user.email}"
    @from       = UserSystem::CONFIG[:email_from].to_s
    @subject    = "[#{UserSystem::CONFIG[:app_name]}] "
    @sent_on    = Time.now
  end
  
  # Unused
#  def build_user_email(assigns)
#    part("multipart/alternative") do |p|
#      UserSystem::CONFIG[:available_content_type].each do |content_type|
#      p.part:content_type => content_type,
#             :body => 
#             render_message("#{@template}.#{content_type.sub(/\//, '.')}.rhtml", assigns) 
#      end
#    end
#  end
 
  def setup_user_email(user)
    @recipients = user.email
    @from       = UserSystem::CONFIG[:email_from].to_s
    @subject    = "[#{UserSystem::CONFIG[:app_name]}] "
    @sent_on    = Time.now
  end 
 
  # Unused
#  def render_message(method_name, body)
#    layout = method_name.match(%r{text\.html\.rhtml}) ? 'layout.text.html.rhtml' : 'layout.text.plain.rhtml'
#    body[:content_for_layout] = render(:file => method_name, :body => body)
#    ActionView::Base.new(template_root, body, self).render(:file => "#{Rails.root}/app/views/layouts_mail/#{layout}")
#  end

  private
  
  def subject_with_head(subject)
    "[#{UserSystem::CONFIG[:app_name]}] #{subject}"
  end
end
