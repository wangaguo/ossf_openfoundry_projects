class ProjectNotify < ActionMailer::Base
  default :from => OPENFOUNDRY_SITE_ADMIN_EMAIL

#  def applied(sent_at = Time.now)
#    @subject    = 'ProjectNotify#applied'
#    @body       = {}
#    @recipients = ''
#    @from       = ''
#    @sent_on    = sent_at
#    @headers    = {}
#  end
  # ProjectNotify.deliver_applied_site_admin(Project.find(1))
  def project_reviewer(project, sent_at = Time.now)
    if project.status == Project::STATUS[:PENDING]
      @subject    = "Project creation reapplied: #{project.name}"
    else
      @subject    = "Project creation request: #{project.name}"
    end
    @project = project
    @user = User.find(project.creator)
    @recipients = Role.find_by_name('project_reviewer').users.map(&:email)  # array is ok
    @from       = OPENFOUNDRY_SITE_ADMIN_EMAIL
    @sent_on    = sent_at
    @headers    = {}
    @content_type = "text/html"
    mail(:to => @recipients,
         :subject => @subject)
  end
  #def applied_site_admin(project, sent_at = Time.now)
  #  @subject    = "Project creation request: #{project.name}"
  #  @body       = { :status_change_url => url_for(:controller => 'site_admin/project',
  #                                                :action => 'change_status_form',
  #                                                :id => project.id) }
  #  @recipients = Role.find_by_name('site_admin').users.map(&:email)  # array is ok
  #  @from       = OPENFOUNDRY_SITE_ADMIN_EMAIL
  #  @sent_on    = sent_at
  #  @headers    = {}
  #end

  def approved(project, replymessage, sent_at = Time.now)
    @subject      = "[#{OPENFOUNDRY_SITE_NAME}] Your project '#{project.name}' has been created!"
    @project_url  = project_url(project, :host => OPENFOUNDRY_HOST)
    @replymessage = replymessage
    @recipients   = User.find(project.creator).email
    @from         = OPENFOUNDRY_SITE_ADMIN_EMAIL
    @sent_on      = sent_at
    @headers      = {}
    @content_type = "text/html"
    mail(:to => @recipients,
         :subject => @subject)
  end

  def rejected(project, replymessage,  sent_at = Time.now)
    @subject      = "[#{OPENFOUNDRY_SITE_NAME}] Your project creation request '#{project.name}' has been rejected!"
    # TODO: maybe only the creator can see the rejected project
    @project_name = project.name
    @replymessage = replymessage
    @recipients   = User.find(project.creator).email
    @from         = OPENFOUNDRY_SITE_ADMIN_EMAIL
    @sent_on      = sent_at
    @headers      = {}
    @content_type = "text/html"
    mail(:to => @recipients,
         :subject => @subject)
  end

  def pending(project, replymessage, sent_at = Time.now)
    @subject      = "[#{OPENFOUNDRY_SITE_NAME}] Your project creation request '#{project.name}' has been pending!"
    # TODO: maybe only the creator can see the rejected project
    @project_url  = edit_project_url(project, :host => OPENFOUNDRY_HOST)
    @project_name = project.name
    @replymessage = replymessage
    @recipients   = User.find(project.creator).email
    @from         = OPENFOUNDRY_SITE_ADMIN_EMAIL
    @sent_on      = sent_at
    @headers      = {}
    @content_type = "text/html"
    mail(:to => @recipients,
         :subject => @subject)
  end

  def s_(key)
    I18n.t key
  end
  helper_method :s_
  def _(key)
    I18n.t key
  end
  helper_method :_

end
