module RitHelper
  def t_priority(val)
    return t(val, :scope => 'ritpriority')
  end

  def t_type(val)
    return t(val, :scope => 'rittickettype')
  end

  def t_status(val)
    return t(val, :scope => 'ritstatus')
  end

  def ticket_update_stat(rit_rdate)
    if !rit_rdate
      return content_tag(:span ,t('rit_table_update_stat') ,:style => "color:#DDDDDD;")
    end
  end

  def ticket_status_color(status)
    status == Rit::STATUS[:OPEN]?color="#FFFFFF":"#FFFFFF"
    status == Rit::STATUS[:FINISH]?color="#EEEEEE":"#FFFFFF"
	  status == Rit::STATUS[:PROCESS]?color="#dfedf3":"#FFFFFF"
	  status == Rit::STATUS[:SUSPENDED]?color="#FEF0F0":"#FFFFFF"
	  status == Rit::STATUS[:DELETE]?color="#F7F7F7":"#FFFFFF"
    return color
  end

  def ticket_status_delete_line(status)
	  status == Rit::STATUS[:DELETE]?delete_line="line-through":"none"
    return delete_line
  end

  def ticket_status_icon(status)
   status == Rit::STATUS[:OPEN]?icon=image_tag("rit_open_24.png", :height => '16', :align => 'middle')+t_status("OPEN"):""
   status == Rit::STATUS[:FINISH]?icon=image_tag("rit_finish_24.png", :height => '16', :align => 'middle')+t_status("FINISH"):""
   status == Rit::STATUS[:PROCESS]?icon=image_tag("rit_process_24.png", :height => '16', :align => 'middle')+t_status("PROCESS"):""
   status == Rit::STATUS[:SUSPENDED]?icon=image_tag("rit_suspended_24.png", :height => '16', :align => 'middle')+t_status("SUSPENDED"):""
   status == Rit::STATUS[:DELETE]?icon=image_tag("rit_delete_24.png", :height => '16', :align => 'middle')+t_status("DELETE"):""
   return icon
  end

  def ticket_priority_icon(priority)
    priority == Rit::PRIORITY[:Urgent]?icon=image_tag("rit_vip_24.png", :height => '16', :align => 'middle'):""
    priority == Rit::PRIORITY[:High]?icon=image_tag("rit_ip_24.png", :height => '16', :align => 'middle'):""
    #priority == Rit::PRIORITY[:Medium]?icon=image_tag("rit_nor_24.png", :height => '16', :align => 'middle'):""
    #priority == Rit::PRIORITY[:Low]?icon=image_tag("rit_low_24.png", :height => '16', :align => 'middle'):""
    return icon
  end

  def ticket_priority_urgent_hight(priority)
    priority == Rit::PRIORITY[:Urgent]?mark = content_tag(:span ,"!!" ,:style => "color:#FF0000;") :""
    priority == Rit::PRIORITY[:High]?mark = content_tag(:span ,"!" ,:style => "color:#FF0000;"):""
    return mark
 end

  def ticket_priority_text(priority)
    priority == Rit::PRIORITY[:Urgent]?text=content_tag(:span ,"#{t_priority('Urgent')}!!" , :style => "color:#FF0000") :""
    priority == Rit::PRIORITY[:High]?text=content_tag(:span ,"#{t_priority('High')}!" , :style => "color:#FF0000") :""
    priority == Rit::PRIORITY[:Medium]?text=content_tag(:span ,t_priority('Medium') , :style => "color:#0000FF") :""
    priority == Rit::PRIORITY[:Low]?text=content_tag(:span ,t_priority('Low')  , :style => "color:#AAAAAA") :""
    return text
 end

 def ticket_assign_short_info(rit_id,user_id)
   if user_id.nil?
     info = image_tag("rit_question_24.png", :height => '16', :align => 'middle') + " " + content_tag(:font ,'NoBody', :color => "#BBBBBB")
   else
     info = image_tag("rit_right_24.png", :height => '16', :align => 'middle') + " " + User.find(user_id).login + tag("br")
     owners_count = User.find(Ritassigns.find_all_by_asRitID(rit_id).map(&:asUserID)).count
     if (owners_count-1) > 0
       info += t('rit_table_assignings', :acount => owners_count-1 )
     end
   end
   return info
 end

 def ticket_owners(owners)
   if owners.empty?
     all_owner = content_tag :span ,'NoBody' ,:style => 'color:#AAAAAA'
   else
     owner_name = Array.new
     for owner in owners
       owner_name.push(owner.login)
     end
       all_owner = content_tag :span ,owner_name*"," ,:style => 'color:#0000FF'
   end
   return all_owner
 end

 def ticket_content(content)
   text = html_escape(content)
   text = simple_format(text)
   text = auto_link(text)
   return text
 end

 def ticket_guest_mail_mask(login_name,login_email)
   masked = ""
   if login_name == "guest"
     masked = login_email.gsub(/@([a-z0-9-]+)/, '@*****') 
   end
   return masked
 end

 def mail_mask(mail)
   return ticket_guest_mail_mask('guest', mail)
 end

 def in_my_watch_list(rit_id,user_id)
    if RitWatchers.find_all_by_rit_id_and_user_id(rit_id,user_id).count > 0
      str = t('rit_link_remove_watch_list')
      act = 'remove'
      confirm = t('rit_ask_remove_watch_list')
    else
      str = t('rit_link_set_to_watch_list')
      act = 'add'
      confirm = t('rit_ask_to_set_watch_list')
    end
    return link_to str, '?watch='+act , :confirm => confirm
 end

 def watching_mark(rit_id,user_id) 
    if RitWatchers.find_all_by_rit_id_and_user_id(rit_id,user_id).count > 0
      return content_tag :span ,'>>' ,:style => 'color:#0000FF'
    end
 end

 def show_pickup_link(rit_id)
   if Ritassigns.find_all_by_asRitID(rit_id).count == 0
     return link_to t('rit_link_nobody_pickup'), '?pickup=pickit', :confirm => t('rit_ask_to_pickup')
   end 
 end

end
