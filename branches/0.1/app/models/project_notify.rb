class ProjectNotify < ActionMailer::Base

  def applied(sent_at = Time.now)
    @subject    = 'ProjectNotify#applied'
    @body       = {}
    @recipients = ''
    @from       = ''
    @sent_on    = sent_at
    @headers    = {}
  end
  # ProjectNotify.deliver_applied_site_admin(Project.find(1))
  def applied_site_admin(project, sent_at = Time.now)
    @subject    = "Project creation request: #{project.unixname}"
    @body       = { :status_change_url => url_for(:controller => 'site_admin/project',
                                                  :action => 'change_status_form',
                                                  :id => project.id) }
    @recipients = Role.find_by_name('site_admin').users.map(&:email)  # array is ok
    @from       = OPENFOUNDRY_SITE_ADMIN_EMAIL
    @sent_on    = sent_at
    @headers    = {}
  end
end
