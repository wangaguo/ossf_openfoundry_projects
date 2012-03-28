class Ritmailer < ActionMailer::Base
  default :from => RIT_EMAIL_DEFAULT


  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.ritmailer.assign_to_notify.subject
  #
  def assign_to_notify(users,rit_id,tLink,proj_id)
    @tLink = tLink
    email_return_info = email_infos(rit_id,proj_id)
    @project_name = email_return_info["project_name"] 
    @title = email_return_info["title"]
    @aUser = email_return_info["creater_name"]
    @content = email_return_info["content"]
    assigns = User.find(users) 
    if RIT_EMAIL_TESTING_MODE
      mail_address = RIT_EMAIL_DEFAULT
    else
      mail_address = assigns.map(&:email)
    end
 
    mail :to => mail_address ,
         :subject => "Assign [#{@project_name}] Ticket [#{@title}] is assign to you. "
  end

  def ticket_reply_to_major(rit_id,reply_id,tLink,proj_id)
    @tLink = tLink
    email_return_info = email_infos(rit_id,proj_id)
    @project_name = email_return_info["project_name"] 
    @title = email_return_info["title"]
    @creator = email_return_info["creator_name"]
    @content = Ritreplies.find(reply_id).content
    @create_time = email_return_info["create_time"]
    @owners = email_return_info["owners"]
    @allmails = email_return_info["send_to"]*", "

    if RIT_EMAIL_TESTING_MODE
      mail_address = RIT_EMAIL_DEFAULT
    else
      mail_address = email_return_info["send_to"]
    end
    mail :from => "#{@creator} via RIT <#{RIT_EMAIL_DEFAULT}>" ,
         :to => mail_address ,
         :subject => "[ #{@project_name} ##{rit_id} ] #{@title}" ,
         :template_name => 'created_notify_to_all'
 end

  def created_notify_to_all(users,rit_id,proj_id,tLink)
    @tLink = tLink
    email_return_info = email_infos(rit_id,proj_id)
    @project_name = email_return_info["project_name"] 
    @title = email_return_info["title"]
    @aUser = email_return_info["creater_name"]
    @content = email_return_info["content"]
    @create_time = email_return_info["create_time"]
    @owners = email_return_info["owners"]
    @allmails = email_return_info["send_to"]*", "

    if RIT_EMAIL_TESTING_MODE
      mail_address = RIT_EMAIL_DEFAULT
    else
      mail_address = users.map(&:email)
    end
    mail :from => "#{@aUser} via RIT <#{RIT_EMAIL_DEFAULT}>" ,
         :to => mail_address,
         :subject => "[#{@project_name}##{rit_id}]#{@title}"
  end

  def create_notify_to_guest(gsmail,rit_id,proj_id,tLink)
    @tLink = tLink
    email_return_info = email_infos(rit_id,proj_id)
    @project_name = email_return_info["project_name"] 
    @title = email_return_info["title"]
    @aUser = email_return_info["creator_name"]
    @content = email_return_info["content"]
 
    if RIT_EMAIL_TESTING_MODE
      mail_address = RIT_EMAIL_DEFAULT
    else
      mail_address = gsmail
    end

    mail :to => mail_address,
         :subject => "[#{@project_name}]Your Request:[#{@title}] is open "

  end

  def email_notify(action,users_in_group,rit_id,reply_id,project_id,link_to_ticket)
    @tLink = link_to_ticket
    email_return_info = email_infos(rit_id,project_id)
    @project_name = email_return_info["project_name"] 
    @title = email_return_info["title"]
    @creator = email_return_info["creator_name"]
    @content = email_return_info["content"]
    
    if action == 'reply'
      @content = Ritreplies.find(reply_id).content
    else
    end
    if action == 'update'
      @content =  Ritreplies.find(reply_id).content
    end
    @create_time = email_return_info["create_time"]
    @owners = email_return_info["owners"]
    if action == 'create' || 'update'
      email_return_info["send_to"].push(users_in_group.map(&:email))
    end

    if RIT_EMAIL_TESTING_MODE
      mail_address = RIT_EMAIL_DEFAULT
      @allmails = (email_return_info["send_to"].uniq)*", "
    else
      mail_address = email_return_info["send_to"].uniq
      @allmails = ''
    end
    mail :from => "#{@creator} via RIT <#{RIT_EMAIL_DEFAULT}>" ,
         :to => mail_address ,
         :subject => "[ #{@project_name} ##{rit_id} ] #{@title}" ,
         :template_name => 'created_notify_to_all'
 end

  def email_infos(rit_id,proj_id)
    project = Project.find(proj_id)
    ticket = Rit.find(rit_id)
    user = User.find(ticket.user_id)
    creator = user.login
    content = ticket.content
    create_time = ticket.created_at
    owners = User.find(Ritassigns.find_all_by_asRitID(rit_id).map(&:asUserID)) 
    owners_name = owners.map(&:login)*", "

    #get email address on creator
    email_address = Array.new
    if user.login=='guest'
      email_address.push(ticket.guestmail)
    else
      email_address.push(user.email)
    end

    #get email address on owners
    owners_mail = owners.map(&:email)
    email_address.push(owners_mail)

    #get email address on reply
    repliers = Ritreplies.find_by_sql("
                                      SELECT r.id,r.rit_fk_id, r.user_id, r.replytype, u.email, u.login 
                                      FROM ritreplies r 
                                      LEFT JOIN users u ON r.user_id=u.id  
                                      WHERE r.rit_fk_id = #{rit_id} and r.replytype = 0 and u.login != 'guest';")
    replier_mails = repliers.map(&:email)
    email_address.push(replier_mails)

    #get email address on reply by guest
    repliers_by_guest = Ritreplies.find_by_sql("
                                      SELECT r.id,r.rit_fk_id, r.user_id, r.replytype, r.guestmail, u.login 
                                      FROM ritreplies r 
                                      LEFT JOIN users u ON r.user_id=u.id  
                                      WHERE r.rit_fk_id = #{rit_id} and r.replytype = 0 and u.login = 'guest';")
    replier_guest_mails = repliers_by_guest.map(&:guestmail)
    email_address.push(replier_guest_mails)
    
    #uniq the emails
    emails = email_address.uniq()


    all_hash = {"project_name" => project.name , 
                "title" => ticket.title ,
                "creator_name" => creator ,
                "content" => content ,
                "create_time" => create_time ,
                "owners" => owners_name.to_s ,
                "send_to" => emails}
    return all_hash
  end
end
