class Ritmailer < ActionMailer::Base
  default :from => "rit@openfoundry.org"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.ritmailer.assign_to_notify.subject
  #
  def assign_to_notify(uEmail,uName,tTitle,fkid,tLink)
    @uName = uName
    @tTitle = tTitle
    @tLink = tLink

    mail :to => uEmail ,
         :subject => "R.I.T Notifition Testing"
  end

  def ticket_reply_to_major(uEmail,uName,tTitle,tLink)
    @uName = uName
    @tTitle = tTitle
    @tLink = tLink
    mail :to => uEmail ,
         :subject => "R.I.T Notifition Testing"

  end

  def created_notify_to_all(users,aUser,fkid,tLink,tTitle)
    @aUser = aUser
    @tLink = tLink
    @title = tTitle
    mail :to => users.map(&:email),
         :subject => 'Ticket has Created'
  end
  def create_notify_to_guest(gsmail,tLink,tTitle)
    @tTitle = tTitle
    @tLink = tLink
    mail :to => gsmail,
         :subject => "Your Request:[#{tTitle}] is open "
  end
end
