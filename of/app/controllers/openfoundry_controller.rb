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

  session :off, :only => [:get_user_by_session_id, :authentication_authorization, :foundry_dump, :foundry_sync, :authentication_authorization_II]
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

    attrs = {
              "vcs" => { "projects" => { "name" => "name",  "vcs" => "vcs" },
                         "users" =>  { "login" => "name" , "salted_password" => "password" } }
            }
    
    module_ = params[:module]
    if not attrs[module_]
      render :text => "wrong module '#{module_}'"
      return
    end

    # projects will be an array of hash
    (projects, users) = ["projects", "users"].map do |obj|
      keys = []
      output_names = [] # values_at(*keys)
      attrs[module_][obj].each_pair {|k, v| keys << k; output_names << v}
      sql = "select #{keys.join(',')} from " + case obj
        when "projects": "projects where #{Project.in_used_projects()}"
        when "users": "users where #{User.verified_users()}"
      end
      ActiveRecord::Base.connection.select_rows(sql).map do |row|
        tmp = {}
        output_names.each_with_index {|n, i| tmp[n] = row[i] }
        tmp
      end
      # or .. Hash[*output_names.zip(row).flatten] ... benchmark ?
    end

    sql= "select distinct F.name, P.id, U.id from 
          users U, projects P, roles_users RU, roles R, functions F, roles_functions RF 
          where 
          F.module = '#{module_}' and
          (R.name='admin' or (RF.role_id = R.id and RF.function_id = F.id)) and
          R.authorizable_id = P.id and 
          R.authorizable_type = 'Project' and 
          RU.role_id = R.id and 
          RU.user_id = U.id and 
          #{User.verified_users(:alias => 'U')} and 
          #{Project.in_used_projects(:alias => 'P')}"
    #render :text => sql; return

    
    #projects = Project.find(:all, :conditions => Project.in_used_projects())
    #users = User.find(:all, :conditions => User.verified_users())
    functions_rows = ActiveRecord::Base.connection.select_rows(sql);

    functions = {}
    functions_rows.each { |fname, pid, uid| functions[fname] = (functions[fname] || []) << [pid, uid] }

    data = {
      #:projects => projects.map { |p| { :id => p.id, :summary => p.summary ,
      #                                  :name => p.name, :vcs => p.vcs } },
      :projects => projects,
      #:users => users.map { |u| { :id => u.id, :name => u.login, :email => u.email,
      #                            :password => u.salted_password } },
      :users => users,
      :functions => functions
    }
    render :text => data.to_json, :layout => false
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
    @options[:per_page] = params[:per_page] || 10
    @options[:page] = params[:page] || 1
    @options[:models] = 
      if params[:chk]
        params[:chk].keys.map{|k| Object.const_get(k)}
      else
        :all
      end

    @results = User.find_with_ferret(@query, @options) if @query
    @lookup = RECORD_LOOKUP_TABLE
  end
  
#  def tag #for displaying taggalbe objects~
#    tag_name=params[:id]	
#    @tagged_object=User.find_tagged_with(tag_name)
#  end
  
  def download
    #render :text => params[:file_name]
    download_project = Project.find_by_name(params[:project_name])
    if download_project
      download_release = Release.find(:first , :conditions => "project_id = '#{download_project.id}' AND version = '#{params[:release_version]}'")
      if download_release
        download_file = Fileentity.find(:first , :conditions => "release_id = '#{download_release.id}' AND path = '#{params[:file_name]}'")
        if download_file
          download_project.project_counter = download_project.project_counter + 1
          download_release.release_counter = download_release.release_counter + 1
          download_file.file_counter = download_file.file_counter + 1
          download_project.save
          download_release.save
          download_file.save
          #render :text => "#{download_project.name} #{download_project.project_counter}\n
          #                #{download_release.version} #{download_release.release_counter}\n
          #                #{download_file.name} #{download_file.path} #{download_file.file_counter}"
          redirect_to "http://of.openfoundry.org/download/#{params[:project_name]}/#{params[:release_version]}/#{params[:file_name]}"
        else
          render :text => 'no this file!'
        end
      else
        render :text => 'no this release!'
      end
    else
      render :text => 'no this project!'
    end
    #redirect_to params[:project_name]
  end
end
