class ProjectNotify < ActionMailer::Base

  def applied(sent_at = Time.now)
    @subject    = 'ProjectNotify#applied'
    @body       = {}
    @recipients = ''
    @from       = ''
    @sent_on    = sent_at
    @headers    = {}
  end
end
