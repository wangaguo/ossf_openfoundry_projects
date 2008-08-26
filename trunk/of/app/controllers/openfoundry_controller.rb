require "rubygems"
require "net/http"
require "uri"
require "json"
require 'base64'

class OpenfoundryController < ApplicationController
  RECORD_LOOKUP_TABLE = {'User' => 'user', 'Project' => 'projects',
                         'News' => 'news', 'Release' => 'releases', 
                         'Fileentity' => 'fileentity' }
  
  def index
  end

  #class Session < ActiveRecord::Base; end # only used by get_session_by_id
  def get_session_by_id(session_id)
    begin
      Marshal.load(Base64.decode64(Session.find_by_session_id(session_id).data))
    rescue
      {}
    end
  end
  private :get_session_by_id

  session :off, :only => [:get_user_by_session_id, :authentication_authorization, :foundry_dump, :foundry_sync, :authentication_authorization_II, :redirect_rt_openfoundry_org]
  def get_user_by_session_id
    s = get_session_by_id(params['session_id'])
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
      user = the_session_data['user']
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
      user = the_session_data['user']
      project_id = Project.find_by_name(project_name, :select => "id").id
      function_names = Function.functions(:authorizable_id => project_id, :user_id => user.id)

      rtn = { :name => user.login, :email => user.email, :function_names => function_names }
    rescue
      rtn = { :name => "guest", :email => "guest@users.openfoundry.org" , :function_names => [] }
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
      sql= "select U.login, P.name, F.name from 
            users U, projects P, roles_users RU, roles R, functions F, roles_functions RF 
            where 
            F.module = 'vcs' and
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
        #functions[u][p][f] = 1
        a = functions[u] = {} if not a = functions[u]
        b = a[p] = {} if not b = a[p]
        b[f] = 1
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
    @results = obj.find_with_ferret(@query, @options) 
    @lookup = RECORD_LOOKUP_TABLE
  end
  
#  def tag #for displaying taggalbe objects~
#    tag_name=params[:id]	
#    @tagged_object=User.find_tagged_with(tag_name)
#  end
  
  def download
    #render :text => params[:file_name]
    download_project = Project.find_by_name(params[:project_name], :conditions => "#{Project.in_used_projects}")
    if download_project
      is_release_admin = fpermit?("release", download_project.id) ? 1 : 0;
      download_release = Release.find(:first, :conditions => ["project_id = ? AND version = ? AND (status = 1 or ?)", download_project.id, params[:release_version], is_release_admin])
      if download_release
        download_file = Fileentity.find(:first, :conditions => ["release_id = ? AND path = ?", download_release.id, params[:file_name]])
        if download_file
          if is_release_admin != 1 # admins don't count!
            ActiveRecord::Base.connection.execute("update projects set project_counter = project_counter + 1 where id=#{download_project.id};")
            ActiveRecord::Base.connection.execute("update releases set release_counter = release_counter + 1 where id=#{download_release.id};")
            ActiveRecord::Base.connection.execute("update fileentities set file_counter = file_counter + 1 where id=#{download_file.id};")
            #render :text => "#{download_project.name} #{download_project.project_counter}\n
            #                #{download_release.version} #{download_release.release_counter}\n
            #                #{download_file.name} #{download_file.path} #{download_file.file_counter}"
          end
          redirect_to "http://of.openfoundry.org/download/#{params[:project_name]}/#{params[:release_version]}/#{params[:file_name]}"
        else
          render :text => _('The file "%{filename}" you are requesting does not exist.') %
            {:filename => CGI.escapeHTML(params[:file_name])}
        end
      else
        render :text => _('The release "%{release}" you are requesting does not exist.') %
          {:release => CGI.escapeHTML(params[:release_version])}
      end
    else
      render :text => _('The project "%{project}" you are requesting does not exist.') %
        {:project => CGI.escapeHTML(params[:project_name])}
    end
    #redirect_to params[:project_name]
  end

  def redirect_rt_openfoundry_org
    #render :text => request.request_uri
    #flash[:notice] = _('The site rt.openfoundry.org has been moved here.')
    redirect_to 'http://of.openfoundry.org/', :status => 307
  end
end
