class ProjectNotify < ActionMailer::Base

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
    @subject    = "Project creation request: #{project.name}"
    @body       = { 
                    :project => project
                  }
    @recipients = Role.find_by_name('project_reviewer').users.map(&:email)  # array is ok
    @from       = OPENFOUNDRY_SITE_ADMIN_EMAIL
    @sent_on    = sent_at
    @headers    = {}
    @content_type = "text/html"
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

  def approved(project, sent_at = Time.now)
    @subject    = "Your project '#{project.name}' has been created!"
    @body       = { :project_url => url_for(:controller => 'projects',
                                            :action => 'show',
                                            :id => project.id) }
    @recipients = User.find(project.creator).email
    @from       = OPENFOUNDRY_SITE_ADMIN_EMAIL
    @sent_on    = sent_at
    @headers    = {}
  end

  def rejected(project, sent_at = Time.now)
    @subject    = "Your project creation request '#{project.name}' has been rejected!"
    # TODO: maybe only the creator can see the rejected project
    @body       = { :project_name => project.name }
    @recipients = User.find(project.creator).email
    @from       = OPENFOUNDRY_SITE_ADMIN_EMAIL
    @sent_on    = sent_at
    @headers    = {}
  end
end
