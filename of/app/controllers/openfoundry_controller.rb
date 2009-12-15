require "rubygems"
require "net/http"
require "uri"
require "json"
require 'base64'

class OpenfoundryController < ApplicationController
  RECORD_LOOKUP_TABLE = {'User' => 'user', 'Project' => 'projects',
                         'News' => 'news', 'Release' => 'releases', 
                         'Fileentity' => 'fileentity', 'Job' => 'jobs',
                         'Reference' => 'references', 'Citation' => 'citations' }
  
  def index
  end

  #class Session < ActiveRecord::Base; end # only used by get_session_by_id
  def get_session_by_id(session_id)
    begin
      #Marshal.load(Base64.decode64(Session.find_by_session_id(session_id).data))
      ::Rails.cache.read("#{session_id}") || {}
    rescue
      {}
    end
  end
  private :get_session_by_id

  def get_session_by_id2(session_id)
    begin
      return {} if session_id !~ /^[0-9a-f]*$/ 
      #rows = ActiveRecord::Base.connection.select_rows("select data from sessions where session_id = '#{session_id}'")
      #return Marshal.load(Base64.decode64(rows[0][0]))
      ::Rails.cache.read("#{session_id}") || {}
    rescue
      {}
    end
  end

  def get_user_by_session_id
    s = get_session_by_id2(params['session_id'])
    u = current_user(s) 
    render :text => "#{u.id} #{u.login}",
      :content_type => 'text/plain'
  end

  # TODO: optimize!!!!!!!!!!
  def authentication_authorization
    #TODO: filter localhost
    #self.class.layout(nil)
    session_id, project_name = params[:SID], params[:projectname]
    begin 
      the_session_data = get_session_by_id(session_id)
      user = the_session_data[:user]
      @name = user.login
      project = Project.find_by_name(project_name)
      if project == nil
        @role = "Other"
      elsif user.has_role?('Admin', project)
        @role = "Admin"
      elsif user.has_role?('Member', project)
        @role = "Member"
      else
        @role = "Other"
      end
      @email = user.email
    rescue
      #guest Other guest@users.openfoundry.org
      @name = "guest"
      @role = "Other"
      @email = "guest@users.openfoundry.org"
    end
    render :text => "#{@name} #{@role} #{@email}" , :layout => false
  end

  # http://of.openfoundry.org/openfoundry/authentication_authorization_II?SID=2702bb3cee31729e29ab61eb8dbce8d9&projectname=openfoundry
  def authentication_authorization_II
    #TODO: filter localhost
    #self.class.layout(nil)
    session_id, project_name = params[:SID], params[:projectname]
    rtn = {}
    begin 
      the_session_data = get_session_by_id(session_id)
      user = the_session_data[:user]
      project_id = Project.find_by_name(project_name, :select => "id").id
      function_names = Function.functions(:authorizable_id => project_id, :user_id => user.id)

      rtn = { :name => user.login, :email => user.email, :function_names => function_names }
    rescue Exception => ex
      rtn = { :name => "guest", :email => "guest@users.openfoundry.org" , :function_names => [] ,:error => ex}
    end
    render :text => rtn.to_json, :layout => false
  end
  
  def foundry_sync
    # default empty password is not allowed
    if params[:secret] != OPENFOUNDRY_JSON_DUMP_PASSWORD || OPENFOUNDRY_JSON_DUMP_PASSWORD == ''
      sleep 10
      render :text => "access denied", :layout => false
      return
    end

    users = projects = functions = 0

    case module_ = params[:module]
    when "vcs"
      projects = ActiveRecord::Base.connection.select_rows("select name, vcs from projects where #{Project.in_used_projects()}")
      users = ActiveRecord::Base.connection.select_rows("select login, salted_password from users where #{User.verified_users()}")
      sql= "select distinct U.login, P.name, F.name from 
            users U, projects P, roles_users RU, roles R, functions F, roles_functions RF 
            where 
            F.module = 'vcs' and
            RF.role_id = R.id and RF.function_id = F.id and
            R.authorizable_id = P.id and 
            R.authorizable_type = 'Project' and 
            RU.role_id = R.id and 
            RU.user_id = U.id and
            P.vcs = #{Project::VCS[:CVS]} and
            #{User.verified_users(:alias => 'U')} and 
            #{Project.in_used_projects(:alias => 'P')}"
      #render :text => sql; return
      functions = {}
      ActiveRecord::Base.connection.execute(sql).each do |u, p, f|
        #functions[u][p][f] = 1
        a = functions[u] = {} if not a = functions[u]
        b = a[p] = {} if not b = a[p]
        b[f] = 1
      end
    when "svn"
      projects = ActiveRecord::Base.connection.select_rows("select name, vcs from projects where #{Project.in_used_projects()}")
      users = ActiveRecord::Base.connection.select_rows("select login, salted_password from users where #{User.verified_users()}")

      sql= "select distinct U.login, P.name, F.name from 
            users U, projects P, roles_users RU, roles R, functions F, roles_functions RF 
            where 
            F.module = 'vcs' and
            RF.role_id = R.id and RF.function_id = F.id and
            R.authorizable_id = P.id and 
            R.authorizable_type = 'Project' and 
            RU.role_id = R.id and 
            RU.user_id = U.id and 
            (P.vcs = #{Project::VCS[:SUBVERSION]} or P.vcs = #{Project::VCS[:SUBVERSION_CLOSE]}) and
            #{User.verified_users(:alias => 'U')} and 
            #{Project.in_used_projects(:alias => 'P')}"
      #render :text => sql; return
      functions = {}
      ActiveRecord::Base.connection.execute(sql).each do |u, p, f|
        #functions[p][u][f] = 1
        a = functions[p] = {} if not a = functions[p]
        b = a[u] = {} if not b = a[u]
        b[f] = 1
      end
    when "rt"
      projects = ActiveRecord::Base.connection.select_rows("select id, name, summary from projects where #{Project.in_used_projects()}")
      users = ActiveRecord::Base.connection.select_rows("select id, login, email from users where #{User.verified_users()}")
      sql= "select distinct U.id, P.id, F.name from 
            users U, projects P, roles_users RU, roles R, functions F, roles_functions RF 
            where 
            F.module = 'Tracker' and
            RF.role_id = R.id and RF.function_id = F.id and
            R.authorizable_id = P.id and 
            R.authorizable_type = 'Project' and 
            RU.role_id = R.id and 
            RU.user_id = U.id and 
            #{User.verified_users(:alias => 'U')} and 
            #{Project.in_used_projects(:alias => 'P')}"
      #render :text => sql; return
      functions = {}
      ActiveRecord::Base.connection.execute(sql).each do |u, p, f|
        #functions[p][f] = [u...]
        a = functions[p] = {} if not a = functions[p]
        b = a[f] = [] if not b = a[f]
        b.push u
      end
    when "sympa"
      users = {}
      ActiveRecord::Base.connection.select_rows(
        "select id, email from users where #{User.verified_users()}").each do |i,e|
        users[i] = e 
      end
      sql= "select distinct P.name, U.id from 
            users U, projects P, roles_users RU, roles R, functions F, roles_functions RF 
            where 
            (RF.role_id = R.id and RF.function_id = F.id and 
               F.name = 'sympa_manage') and
            R.authorizable_id = P.id and 
            R.authorizable_type = 'Project' and 
            RU.role_id = R.id and 
            RU.user_id = U.id and 
            #{User.verified_users(:alias => 'U')} and 
            #{Project.in_used_projects(:alias => 'P')}"
      #render :text => sql; return
      functions = 
        ActiveRecord::Base.connection.select_rows(sql)
    else
      render :text => "wrong module '#{module_}'"
      return
    end
    data = { :projects => projects, :users => users, :functions => functions }
    render :text => data.to_json, :layout => false
    #render :text => JSON.pretty_generate(data), :layout => false
  end
  
  def foundry_dump # TODO: optimize !!!!
    #if !params[:secret] || params[:secret].crypt("$1$foobar") != "$1$foobar$jghwt7tiDrPE99XAhdtUe0"
    # default empty password is not allowed
    if params[:secret] != OPENFOUNDRY_JSON_DUMP_PASSWORD || OPENFOUNDRY_JSON_DUMP_PASSWORD == ''
      sleep 10
      render :text => "access denied", :layout => false
      return
    end

    projects = Project.find(:all, :conditions => Project.in_used_projects())
    users = User.find(:all, :conditions => User.verified_users())

    data = {
      :projects => projects.map { |p| { :id => p.id, :summary => p.summary , :name => p.name, :vcs => p.vcs } },
      :users => users.map { |u| { :id => u.id, :name => u.login, :email => u.email, :password => u.salted_password } },
      :relations => {
        :admin => projects.inject([]) { |all, p| all + p.admins().map { |u| [p.id, u.id] } },
        :member => projects.inject([]) { |all, p| all + p.members().map { |u| [p.id, u.id] } }
      }
    }
    render :text => data.to_json, :layout => false
  end

  def load_data
    url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJson.html?secret=' + params[:secret]
    r = Net::HTTP.get_response( URI.parse( url ) )
    data = JSON.parse(r.body)

#    data["projects"].each do |pd|
#      p = Project.new({ :summary => pd["summary"], :name => pd["name"] })
#      p.id = pd["Id"]
#      p.save!
#    end

    data["users"].each do |ud|
      u = User.new({ :login => ud["Name"], :email => ud["Email"], 
        :salted_password => ud["salted_password"], :salt => ud["salt"],
        :verified => 1 })
      u.id = ud["Id"]
      u.save!
    end

#    ph = {}
#    Project.find_all().each { |p| ph[p.id] = p }
#    uh = {}
#    User.find_all().each { |u| uh[u.id] = u }

#    bad = ""
#    data["relations"]["member"].each do |rd|
#      uh[rd[1]].has_role("Member", ph[rd[0]])
##      bad += rd[1].to_s if uh[rd[1]].nil?
#    end
#    data["relations"]["admin"].each do |rd|
#      uh[rd[1]].has_role("Admin", ph[rd[0]])
##      bad += rd[1].to_s if uh[rd[1]].nil?
#    end



    
    render :text => data.inspect, :layout => false
#    render :text => bad, :layout => false
  end
  
  def is_project_name
    rtn = Project.find_by_name(params[:projectname]) ? "1" : "0"
    render :text => rtn, :layout => false
  end
  
  def search #for search!!! TODO: catalog and optimize?
    @query = params[:query_adv] || params[:query]#.split(' ').join(' OR ')
    query = (@query+" ").gsub(/([\w])+[\s]+/){|m|
      $0 = ""; m.scan(/[a-z]+|\d+/i).each{|q| q.match(/^[a-z]+$/i)? $0+=" *#{q}* " : $0+=" #{q} "}; $0;}
    @options = {}
    @options[:per_page] = params[:per_page] || 20
    @options[:page] = params[:page] || 1
    @options[:models] = 
      if params[:chk]
        params[:chk].keys.map{|k| Object.const_get(k)}
      else
        :all
      end
    obj = @options[:models] == :all ? User : @options[:models].first
    @results = obj.find_with_ferret(query, @options) 
    @lookup = RECORD_LOOKUP_TABLE
  end
  
#  def tag #for displaying taggalbe objects~
#    tag_name=params[:id]	
#    @tagged_object=User.find_tagged_with(tag_name)
#  end
  
  def download
    #check if project-release-file is match
    check_download_consistancy
    unless @error_msg.empty?
      render :text => @error_msg
      return
    end
    add_one_to_download_counter

    download_path_saved = CGI::escape( "#{@project.name}/#{@release.version}/#{@file.path}" )
    #restore url encoding for slash(/)
    download_path_saved.gsub!('%2F', '/')
    #chech if file has a mandatory survey
    #TODO login user?
    if( survey_available? 
        #and (session[:saved_download_path] != download_path_saved )
      )
      #save directly download link to tmp session
      #session[:saved_download_path] = download_path_saved
      session[:tmp_path] = download_path_saved

      survey = @file.survey

      #go to fill downloader form
      redirect_to( downloader_path( @project.name, @release.version, @file.path, survey.id )) 

      return
    end

    redirect_to "#{request.protocol}of.openfoundry.org/download/#{download_path_saved}"
  end

  def redirect_rt_openfoundry_org
    #/foundry
    #/foundry/[user|project|download|trove|help]
    #/foundry/project/[forum|source|downlaod|wiki]
    #/foundry/project/download/attachement
    #/viewvc
    path = request.env['PATH_INFO']
    q = nil
    controller = :openfoundry
    action = nil
    case path
    when /^\/foundry(.*)$/i
      case $1
      when /\/project(.*)/i
        controller = :projects
        q=params['queue']||params['Queue']||1
        case $1
        when /\/tracker(.*)/i
          action = :rt
        when /\/download(.*)/i
          case $1
          when /\/Attachment\/(\d+)\/(\d+)\/(.*)/i
            f = Fileentity.find_by_meta("#{$1},#{$2}")
            if f
              redirect_to "http://of.openfoundry.org/download_path/#{f.release.project.name}/#{f.release.version}/#{f.path}"
            else
              redirect_to "http://of.openfoundry.org/releases/top"
            end
            return
          end
          action = :download
        when /\/wiki(.*)/i
          action = :kwiki
        when /\/forum(.*)/i
          action = :sympa
        when /\/source(.*)/i
          action = :viewvc
        end
        redirect_to "http://of.openfoundry.org/#{controller}/#{q}/#{action}"
      when /\/download(.*)/i
        case $1
        when /\/(\d+)\/(\d+)\/(.*)/
          f = Fileentity.find_by_meta("#{$1},#{$2}")
          logger.info("")
          if f
            redirect_to "http://of.openfoundry.org/download_path/#{f.release.project.name}/#{f.release.version}/#{f.path}"
          else
            redirect_to "http://of.openfoundry.org/releases/top"            
          end
        else
          redirect_to "http://of.openfoundry.org/releases/top"
        end
      end   
    when /\/viewvc/i
    else
      redirect_to 'http://of.openfoundry.org/', :status => 307
    end
  end

  protected

  def survey_available?
    #@file = Fileentity.find_by_path(params["file_name"], :include => [:survey])
    @file and @file.survey and @file.survey.available?
  end

  def add_one_to_download_counter
     #ActiveRecord::Base.connection.execute("update `projects` set `project_counter` = 
     #                   `project_counter` + 1 where `id` ='#{@project.id}'")
     @project.redis_counter_project_counter_inc                   
     #ActiveRecord::Base.connection.execute("update `releases` set `release_counter` = 
     #                   `release_counter` + 1 where `id` = '#{@release.id}'")
     @release.redis_counter_release_counter_inc                   
     #ActiveRecord::Base.connection.execute("update `fileentities` set `file_counter` = 
     #                   `file_counter` + 1 where `id` = #{@file.id}")
     @file.redis_counter_file_counter_inc                   
  end
end
