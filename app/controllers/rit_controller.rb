class RitController < ApplicationController

 find_resources :parent => 'project', :child => 'rit', :parent_id_method => 'project_id', :child_rename => 'rit'

 #before_filter :check_permission

  def userID
      return current_user.id
  end

  def index
    @module_name = _('rit_index_title')
    #session[:user] = User.find('201626')
    #session[:user] = nil
 
    @userID = userID
    @rit = Rit.where(:project_id => params[:project_id])
    if !params[:k].nil?
      @k=params[:k]
      keyword = "%#{@k}%"
      @rit = @rit.where("rits.title like ?",keyword)
      @knums = @rit.count
      shortOfkword = "&k=#{@k}"
    else
      @k=""
      @knums = ""
      shortOfkword = ""
    end
   
    order_rq = request['orderby']
    short_rq = request['short']
    orderSql = "rits.created_at DESC"
    if short_rq=='DESC'
      short_str = 'DESC'
      short_rev = 'ASC'
      shorting = " v"
    else
      short_str = 'ASC'
      short_rev = 'DESC'
      shorting = " ^"
    end
   
    if order_rq=='cdate'
      orderSql = "rits.created_at #{short_str}"
      @orderLinkA = "?orderby=cdate&short=#{short_rev}"+shortOfkword
      @shortMarkA = shorting
    else
      @orderLinkA = "?orderby=cdate&short=DESC"+shortOfkword
      @shortMarkA = ""
    end
    if order_rq=='rdate'
      orderSql = "MAX(ritreplies.created_at) #{short_str}"
      @orderLinkB = "?orderby=rdate&short=#{short_rev}"+shortOfkword
      @shortMarkB = shorting
    else
      @orderLinkB = "?orderby=rdate&short=DESC"+shortOfkword
      @shortMarkB = ""
    end
    if order_rq=='stat'
      orderSql = "rits.status #{short_str}"
      @orderLinkC = "?orderby=stat&short=#{short_rev}"+shortOfkword
      @shortMarkC = shorting
    else
      @orderLinkC = "?orderby=stat&short=DESC"+shortOfkword
      @shortMarkC = ""
    end 
    @rit = @rit.find(:all, :joins=>"LEFT JOIN ritreplies ON rits.id=ritreplies.rit_fk_id AND ritreplies.replytype=0 LEFT JOIN users ON rits.user_id=users.id LEFT JOIN ritassigns ON asRitID=rits.id LEFT JOIN users AU ON ritassigns.asUserID=AU.id ", :select=>"rits.* ,users.login as uname ,users.icon as avator ,MAX(ritreplies.created_at) AS rdate ,COUNT(ritreplies.rit_fk_id) AS nums, COUNT(ritassigns.asRitID) as assignNums, MAX(AU.login) as firstAssign" ,:group=>"rits.id" , :order=> orderSql )
    @rit = @rit.paginate :page => params[:page], :per_page => 25

  end

  def show
    @module_name = _('rit_index_title')
    
    @userID=userID
    @rit = Rit.find(params[:id])
    assUsers = Ritassigns.where(:asRitID => params[:id])
    @assUsers = assUsers.find(:all ,:joins => "LEFT JOIN users u ON u.id = ritassigns.asUserID", :select => "ritassigns.*,u.login")

    @uName = User.find(@rit.user_id)
    @aName = User.find(@rit.assign_user_id) rescue nil 
    #Select the attach from main ticket
    @attach = Ritfile.where(:ritFK => params[:id], :fromRit => 1).all
     
    #Select out the replay from ritreplays table
    
    ritreplies = Ritreplies.where(:rit_fk_id => params[:id], :replytype => [0,1])
    @ritreplies = ritreplies.find(:all, :joins => "LEFT JOIN users u ON u.id = ritreplies.user_id", :select => "ritreplies.*,u.login" )
    
    #Getting ready new replay below the form
    @rName = User.find(@userID)
    #check the role from rit_member & rit_admin
    @role = checkrole(@userID,'rt_member')
     
  end

  def new
    @module_name = _('rit_index_title')
    
    @Name=Project.find(params[:project_id])
    @pjMeb=projectOfMembers
    @priority = Rit::PRIORITY
    @type = Rit::TICKETTYPE
    @userID=userID
    @uName = User.find(userID)
    @rit = Rit.new
  end

  def reply
     if current_user.login == 'guest' and verify_recaptcha == false
       cookies[:guestmail]=params[:ritreply][:guestmail]
       cookies[:title]=params[:ritreply][:title]
       cookies[:content]=params[:ritreply][:content]
       flash[:error] = _('rit_msg_captcha_error')
        redirect_to :back
        return
    end
   @ritreply = Ritreplies.new(params[:ritreply])
    pid=params[:project_id] 
    if @ritreply.save
        
        rt = Rit.find(params[:id])
        aU = User.find(rt.user_id)
        uName = aU.login
        if uName!="guest"
          uEmail = aU.email
        else
          uEmail = rt.guestmail
        end

        tTitle = rt.title
        #tLink = "http://#{request.env["SERVER_NAME"]}/of/projects/#{params[:project_id]}/rit/#{params[:id]}"
        tLink = request.env["HTTP_REFERER"]

        Ritmailer.ticket_reply_to_major(uEmail,uName,tTitle,tLink).deliver
    
        fKid = @ritreply.id
        if !params[:ritfile].blank? 
          if !params[:ritfile][:filename].nil?
            RitFileUp(params[:ritfile][:filename],fKid,0,1)
          end
          if !params[:ritfile][:filenameB].nil?
            RitFileUp(params[:ritfile][:filenameB],fKid,0,1)
          end
          if !params[:ritfile][:filenameC].nil?
            RitFileUp(params[:ritfile][:filenameC],fKid,0,1)
          end
          if !params[:ritfile][:filenameD].nil?
            RitFileUp(params[:ritfile][:filenameD],fKid,0,1)
          end
          if !params[:ritfile][:filenameE].nil?
            RitFileUp(params[:ritfile][:filenameE],fKid,0,1)
          end
        end
        flash[:notice]=_('rit_msg_reply_ok')
        cookies.delete :content
        redirect_to :action => "show" , :project_id => pid , :id => params[:id]
    else
        flash[:error]=_('rit_msg_add_error')
        cookies[:content]=params[:ritreply][:content]
        redirect_to :action => "show" ,:project_id => pid , :id => params[:id]
    end

  end

  def create
    if current_user.login == 'guest' and verify_recaptcha == false
       cookies[:guestmail]=params[:rit][:guestmail]
       cookies[:title]=params[:rit][:title]
       cookies[:content]=params[:rit][:content]
       flash[:error] = _('rit_msg_captcha_error')
        redirect_to :back
        return
    end
    @rit = Rit.new(params[:rit])
    if @rit.save
      fkid = @rit.id
      tTitle = params[:rit][:title]
      tLink = "http://#{request.env["SERVER_NAME"]}/of/projects/#{params[:project_id]}/rit/#{fkid}"
      users = projectOfMembers
      aU = User.find(params[:rit][:user_id])
      #Ritmailer.created_notify_to_all(users,aU.login,fkid,tLink,tTitle).deliver

      if current_user.login=="guest"
        Ritmailer.create_notify_to_guest(params[:rit][:guestmail],tLink,tTitle).deliver
      end

      auid = params[:rit][:assign_user_id]
      if auid.to_i != 0.to_i
        u = User.find(params[:rit][:assign_user_id])
        um = u.email
        uu = u.login
        tT = params[:rit][:title]
       # Ritmailer.assign_to_notify(um,uu,tT,fkid,tLink).deliver
       end

       #multi assign users
        if !params[:assigns].blank?
            assign = params[:assigns]
            assign.each do |ass|
              as = Ritassigns.new
              as.asRitID = fkid
              as.asUserID = ass 
              as.save
            end
        end


       #call RitFileUp
       fmsgg=""
        if !params[:ritfile].blank?
          if !params[:ritfile][:filename].nil?
            fmsgg+=RitFileUp(params[:ritfile][:filename],fkid,1,0)
          end
          if !params[:ritfile][:filenameB].nil?
            fmsgg+=RitFileUp(params[:ritfile][:filenameB],fkid,1,0)
          end
          if !params[:ritfile][:filenameC].nil?
            fmsgg+=RitFileUp(params[:ritfile][:filenameC],fkid,1,0)
          end
          if !params[:ritfile][:filenameD].nil?
            fmsgg+=RitFileUp(params[:ritfile][:filenameD],fkid,1,0)
          end
          if !params[:ritfile][:filenameE].nil?
            fmsgg+=RitFileUp(params[:ritfile][:filenameE],fkid,1,0)
          end
        end
        flash[:notice]=_('rit_mag_add_ok')
        if !fmsgg.blank?
          flash[:error]=fmsgg
        end
        pid=params[:project_id]
        cookies.delete :content
        cookies.delete :title
        redirect_to :controller => "rit" , :action => "index" , :project_id => pid
    else
       flash[:error]=_('rit_msg_add_error')
       #redirect_to :action => "new"
       cookies[:title]=params[:rit][:title]
       cookies[:content]=params[:rit][:content]
       redirect_to :back
    end
    
    
  end

  def changestat
    @module_name = _('rit_index_title')
    if current_user.login!="guest"
     @pjName=Project.find(params[:project_id])
     @pjMeb=projectOfMembers
     @priority = Rit::PRIORITY
     @type = Rit::TICKETTYPE
     @status = Rit::STATUS
     @userID=userID
     @uName = User.find(userID)
     @rit = Rit.find(params[:id])
     @asses=assignTable(params[:project_id],params[:id])
    else
      redirect_to :back
    end

  end

  def updatestat
    if current_user.login =="guest"
      redirect_to :root
    else
      @rit = Rit.find(params[:id])
      tT=@rit.title
     fkid = @rit.id
     logStr=''
     ##### Change Ticket infos ########
     p = Rit::PRIORITY
     s = Rit::STATUS
     t = Rit::TICKETTYPE
     tLink = "http://#{request.env["SERVER_NAME"]}/of/projects/#{params[:project_id]}/rit/#{fkid}"
     ########### multi assign/remove users ##################
     assign = params[:assigns]
     asses=assignTable(params[:project_id],params[:id])
       if (!(params[:assigns].blank?) && !(asses.nil?))
         asses.each do |am|
          if ((am.HasAssign.nil?) && (assign.include?(am.id.to_s)))
              asa = Ritassigns.new
              asa.asRitID = fkid
              asa.asUserID = am.id
              asa.save
              u = User.find(am.id)
              uu = u.login
              um = u.email
              logStr+="user #{uu} is Assigned. \n "
              Ritmailer.assign_to_notify(um,uu,tT,fkid,tLink).deliver
          end
          if ((!am.HasAssign.nil?) && (!assign.include?(am.id.to_s)))
             Ritassigns.destroy_all(:asUserID => am.id, :asRitID => am.HasAssign)
             u = User.find(am.id)
             uu = u.login
             logStr+="user #{uu} is Removed. \n "
          end
          end 
       end
    
         #if something has records in table but params[:assigns] wants delete all
          if ((params[:assigns].blank?) && !(asses.empty?))
            Ritassigns.destroy_all(:asRitID => fkid)
            a_ReMoveAllAssign=1
            logStr+="All assigns are removed. \n"
          end

   
          assign_before = @rit.assign_user_id.to_s
          assign_after = params[:rit][:assign_user_id].to_s
    
          priority_before = @rit.priority.to_s
          priority_after = params[:rit][:priority].to_s
          p = p.index(priority_after.to_i)

          status_before = @rit.status.to_s
          status_after = params[:rit][:status].to_s
          s = s.index(status_after.to_i)

          ttype_before = @rit.tickettype.to_s
          ttype_after = params[:rit][:tickettype]
          t = t.index(ttype_after.to_i)
       
         if priority_before != priority_after
           logStr+= "Priority has change to #{p}.\n "
          end

         if status_before != status_after
           logStr+= "Status has change to #{s}.\n"
         end

         if ttype_before != ttype_after
            logStr+= "Type has change to #{t}.\n"
         end
          #####Change Ticket info End ######

          @rit.update_attributes(params[:rit])

          rlog = Ritreplies.new()
          rlog.rit_fk_id = params[:id]
          rlog.user_id = userID
          rlog.title = '[log]' + @rit.title
          rlog.content = logStr
          rlog.replytype = 1
          rlog.guestmail = 'rit@openfoundry.com'
          ##### if nothing change but still submit then not save to data
          if logStr != ''
            rlog.save
          end
          flash[:notice]=_('rit_msg_changestat')
          redirect_to project_rit_index_path
    end
  end

  def uploadmorefile
    @module_name = _('rit_index_title')
    @userID=userID
    @rit = Rit.find(params[:id])
    if current_user.id != @rit.user_id or current_user.login=='guest'
      redirect_to :back
      flash[:error]=_('rit_msg_upload_not_yours')
      return
    end
      assUsers = Ritassigns.where(:asRitID => params[:id])
      @assUsers = assUsers.find(:all ,:joins => "LEFT JOIN users u ON u.id = ritassigns.asUserID", :select => "ritassigns.*,u.login")
      @uName = User.find(@rit.user_id)
      @attach = Ritfile.where(:ritFK => params[:id], :fromRit => 1).all

  end

  def uploadingmore
    @rit = Rit.find(params[:id])
    if current_user.id != @rit.user_id or current_user.login=='guest'
      redirect_to :root
      flash[:error]=_('rit_msg_upload_not_yours')
      return
    end
     fkid = params[:id]
        #call RitFileUp
        if !params[:ritfile].blank?
            fmsgg=""
            if !params[:ritfile][:filename].nil?
              fmsgg+=RitFileUp(params[:ritfile][:filename],fkid,1,0)
            end
            if !params[:ritfile][:filenameB].nil?
              fmsgg+=RitFileUp(params[:ritfile][:filenameB],fkid,1,0)
            end
            if !params[:ritfile][:filenameC].nil?
              fmsgg+=RitFileUp(params[:ritfile][:filenameC],fkid,1,0)
            end
            if !params[:ritfile][:filenameD].nil?
              fmsgg+=RitFileUp(params[:ritfile][:filenameD],fkid,1,0)
            end
            if !params[:ritfile][:filenameE].nil?
              fmsgg+=RitFileUp(params[:ritfile][:filenameE],fkid,1,0)
            end
        
            flash[:notice]=_('rit_msg_upload_ok')
            butSomeError = ""
            if !fmsgg.blank?
              flash[:error]=fmsgg
              butSomeError = ", but " + fmsgg
            end
          
            logStr ="User #{current_user.login} has upload some files"+ butSomeError
            rlog = Ritreplies.new()
            rlog.rit_fk_id = params[:id]
            rlog.user_id = userID
            rlog.title = '[log] uploading attachment'
            rlog.content = logStr
            rlog.replytype = 1
            rlog.guestmail = 'rit@openfoundry.com'
            ##### if nothing change but still submit then not save to data
            if logStr != ''
              rlog.save
            end
        else
          flash[:error] = _('rit_mag_upload_empty_error')
        end
        pid=params[:project_id]
        redirect_to :action => "show" , :project_id => pid , :id => params[:id]
  end

  def deletefile
    @module_name = _('rit_index_title')
    @userID=userID
    @rit = Rit.find(params[:id])
    if current_user.id != @rit.user_id or current_user.login=='guest'
      redirect_to :back
      flash[:error]=_('rit_msg_upload_not_yours')
      return
    end
      assUsers = Ritassigns.where(:asRitID => params[:id])
      @assUsers = assUsers.find(:all ,:joins => "LEFT JOIN users u ON u.id = ritassigns.asUserID", :select => "ritassigns.*,u.login")

      @uName = User.find(@rit.user_id)
      @attach = Ritfile.where(:ritFK => params[:id], :fromRit => 1).all
  end

  def deletingfile
    @rit = Rit.find(params[:id])
    if current_user.id != @rit.user_id or current_user.login=='guest'
      redirect_to :root
      flash[:error]=_('rit_msg_upload_not_yours')
      return
    end
   atts = params[:ratts]
       if !params[:ratts].blank?
         logStr=""
         atts.each do |a|
              rfile = Ritfile.find(a.to_i)
              rfname = rfile.filename
              rfoname = rfile.OrigName
              directory = "public/of/rit_attachs"
              newname =  rfname
              remFile = File.join(directory, newname)
              if File.delete(remFile)
                Ritfile.destroy_all(:id => rfile.id)
                logStr+="the file #{rfoname} has deleted. \n "
             end
          end 
          rlog = Ritreplies.new()
          rlog.rit_fk_id = params[:id]
          rlog.user_id = userID
          rlog.title = '[log] deleted attachment'
          rlog.content = logStr
          rlog.replytype = 1
          rlog.guestmail = 'rit@openfoundry.com'
          rlog.save
          flash[:notice]=_('rit_msg_attach_delete_ok')
          redirect_to :action => "show" , :project_id => params[:project_id] , :id => params[:id]
       else
         flash[:error]=_('rit_msg_table_deleteattachment')
         redirect_to :back
       end
  end

  def addcommentR
   @module_name = _('rit_index_title')
  
   @rit = Rit.find_by_id(params[:id])
   @cmR = Ritreplies.where(:rit_fk_id => params[:id], :replytype => 2 )
   @cm = Ritreplies.new() 
   @uName = User.find_by_id(@rit.user_id)
  end

  def insertcommentR
   rit = Rit.find_by_id(params[:id])
   uName = User.find_by_id(userID)
   cm = Ritreplies.new()
   cm.rit_fk_id = params[:id]
   cm.user_id = 0
   cm.title = '[Comment]' + rit.title
   cm.content = uName.login.to_s + ' : ' + params[:ritreplies][:content]
   cm.replytype = 2
   cm.save
   redirect_to project_rit_index_path
  end

  def addcommentRy
   @module_name = _('rit_index_title')
   
   @rry = Ritreplies.find_by_id(params[:id])
   @cmR = Ritreplies.where(:rit_fk_id => params[:id], :replytype => 3 )
   @cm = Ritreplies.new()
   @uName = User.find_by_id(@rry.user_id)

  end

  def insertcommentRy
    rrt = Ritreplies.find_by_id(params[:id])
    uName = User.find_by_id(userID)
    cm = Ritreplies.new()
    cm.rit_fk_id = params[:id]
    cm.user_id = userID
    cm.title = '[Comment]' + rrt.title
    cm.content = uName.login.to_s + ' : ' + params[:ritreplies][:content]
    cm.replytype = 3
    cm.save
    redirect_to project_rit_index_path
  end

  def assignlist
    @module_name = _('rit_index_title')
    @uName = User.find(userID)
    @kk=checkrole(userID,'rt_member') 
    
    
    # :assign_user_id => @uName.id
    
    @rit = Rit.find_by_sql("
    select rits.* ,users.login as uname ,users.icon as avator ,MAX(ritreplies.created_at) AS rdate ,COUNT(ritreplies.rit_fk_id) AS nums, COUNT(ritassigns.asRitID) as assignNums, MAX(AU.login) as firstAssign from rits
    RIGHT JOIN ritassigns RA ON RA.asRitID=rits.id AND RA.asUserID=#{@uName.id}
    LEFT JOIN ritreplies ON rits.id=ritreplies.rit_fk_id AND ritreplies.replytype=0 
    LEFT JOIN users ON rits.user_id=users.id 
    LEFT JOIN ritassigns ON ritassigns.asRitID=rits.id
    LEFT JOIN users AU ON ritassigns.asUserID=AU.id 
    WHERE project_id=#{params[:project_id]}
    group by rits.id
    order by rits.created_at DESC
                           ")
    
    @rit = @rit.paginate :page => params[:page], :per_page => 25
  end

  #the file upload function
  def RitFileUp(upload,fKid,forRit,forReply)
      name =  upload.original_filename
      directory = "public/of/rit_attachs"
      # create the file path
      path = File.join(directory, name)
      # write the file
      File.open(path, "wb") { |f| f.write(upload.read) }
      # rename file
      newname =  Time.now.to_i.to_s + Time.now.usec.to_s + File.extname(path)
      orgFile = path
      remFile = File.join(directory, newname)
      File.rename(orgFile ,remFile)
      thetype = upload.content_type
      theFileSize = upload.size
      #make filename to database
      if theFileSize < 2500000
        ritfile = Ritfile.new
        ritfile.ritFK = fKid
        ritfile.filename = newname
        ritfile.fromRit = forRit
        ritfile.fromReply = forReply
        ritfile.filetype = thetype.to_s
        ritfile.OrigName = name
        ritfile.save
        fumsg=""
      else
        File.delete(remFile)
        fumsg = t('rit_msg_oversize', :ufname => name.to_s ,:ufsize => theFileSize.to_s)
      end
      return fumsg
  end
  
  #input value is user_id and rit's role name if it's ,return the u.login, 
  #if if not return nil
  # Role name string is rit_admin or rit_member
  def checkrole(uid,functionRoleName)
    rU = User.find_by_sql("
        select distinct U.id, U.login, U.icon, R.name as role_name, FC.name as func_name 
           from users U 
			  inner join 
			     roles_users RU on U.id = RU.user_id 
			  inner join 
			     roles R on RU.role_id = R.id  
			  Left join 
			     roles_functions RF ON RF.role_id = RU.role_id 
			  Left join 
			     functions FC ON FC.id = RF.function_id AND FC.module='Tracker' 
			  where R.authorizable_id = #{params[:project_id]}
			    AND R.authorizable_type= 'project' 
			    AND FC.name='#{functionRoleName}' 
			    AND U.id=#{uid}
			  ORDER BY U.id;")

    if rU.empty?
      return 'norole'
    else
      return rU[0]['func_name']
    end

  end

  def projectOfMembers
    pmembers = User.find_by_sql("
    	select distinct U.id, U.login, U.icon, U.email, R.name as role_name
	from users U
	  inner join roles_users RU on U.id = RU.user_id
	  inner join roles R on RU.role_id = R.id
	where
	  R.authorizable_id = #{params[:project_id]} and 
	  R.authorizable_type= 'Project'
	ORDER BY U.id;
	")

     return pmembers
  end

  def assignTable(pjid,ticketid)
     a = User.find_by_sql("
      select distinct U.id, U.login, U.icon, A.asRitID as HasAssign
      from users U
        inner join roles_users RU on U.id = RU.user_id
        inner join roles R on RU.role_id = R.id
        left join ritassigns A on A.asUserID=RU.user_id and A.asRitID= #{ticketid}
      where
        R.authorizable_id = #{pjid} and 
        R.authorizable_type= 'Project'
        ORDER BY U.id;
        ")
     return a
 end

end
