require "rubygems"
require "json"
require "net/http"
require "uri"
require "json"

class OpenfoundryController < ApplicationController

  def index
  end

  # private
  def get_session_by_id(session_id)
    # ref: actionpack-2.0.2/lib/action_controller/cgi_process.rb   def session
    options = ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.stringify_keys
    options.merge!('session_id' => session_id)
    puts options.inspect
    s = CGI::Session.new(request.cgi, options)
  end
  session :off, :only => :get_user_by_session_id
  def get_user_by_session_id
    s = get_session_by_id(params['session_id'])
    u = current_user(s) 
    render :text => "#{u.id} #{u.login}",
      :content_type => 'text/plain'
  end

  # TODO: optimize!!!!!!!!!!
  def authentication_authorization
    #self.class.layout(nil)
    session_id, project_unixname = params[:SID], params[:projectUnixName]
    if the_session_data = get_session_by_id(session_id)
      user = the_session_data['user']
      @name = user.login
      project = Project.find_by_unixname(project_unixname)
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
    else
      #guest Other guest@users.openfoundry.org
      @name = "guest"
      @role = "Other"
      @email = "guest@users.openfoundry.org"
    end
    render :text => "#{@name} #{@role} #{@email}" , :layout => false
  end
  def foundry_dump # TODO: optimize !!!!
    #if !params[:secret] || params[:secret].crypt("$1$foobar") != "$1$foobar$jghwt7tiDrPE99XAhdtUe0"
    # default empty password is not allowed
    if params[:secret] != OPENFOUNDRY_JSON_DUMP_PASSWORD || OPENFOUNDRY_JSON_DUMP_PASSWORD == ''
      sleep 10
      render :text => "access denied", :layout => false
      return
    end

    data = {
      :projects => Project.find(:all).map { |p| { :Id => p.id, :summary => p.summary , :UnixName => p.unixname, :VCS => p.vcs } },
      :users => User.find(:all).map { |u| { :Id => u.id, :Name => u.login, :Email => u.email, :Password => u.salted_password } },
      :relations => {
        :admin => Project.find(:all).inject([]) { |all, p| all + p.admins().map { |u| [p.id, u.id] } },
        :member => Project.find(:all).inject([]) { |all, p| all + p.members().map { |u| [p.id, u.id] } }
      }
    }
    render :text => data.to_json, :layout => false
  end

  def load_data
    url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJson.html?secret=' + params[:secret]
    r = Net::HTTP.get_response( URI.parse( url ) )
    data = JSON.parse(r.body)

#    data["projects"].each do |pd|
#      p = Project.new({ :summary => pd["summary"], :unixname => pd["UnixName"] })
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
  def is_project_unixname
    rtn = Project.find_by_unixname(params[:projectUnixName]) ? "1" : "0"
    render :text => rtn, :layout => false
  end
  def search #for search!!! TODO: catalog and optimize?
    query=params[:query]
    #catalog=params[:catalog]
    
    @result=[]
    #catalog.each |catalog| do 
        @result << User.find_by_contents(query)
	@result << Project.find_by_contents(query)
    #end
  end
  def tag #for displaying taggalbe objects~
    tag_name=params[:id]	
    @tagged_object=User.find_tagged_with(tag_name)
  end
  
  def download
    #render :text => params[:file_name]
    download_project = Project.find_by_unixname(params[:project_name])
    if download_project
      download_release = Release.find(:first , :conditions => "project_id = '#{download_project.id}' AND name = '#{params[:release_name]}'")
      if download_release
        download_file = Fileentity.find(:first , :conditions => "release_id = '#{download_release.id}' AND path = '#{params[:file_name]}'")
        if download_file
          download_project.project_counter = download_project.project_counter + 1
          download_release.release_counter = download_release.release_counter + 1
          download_file.file_counter = download_file.file_counter + 1
          download_project.save
          download_release.save
          download_file.save
          #render :text => "#{download_project.unixname} #{download_project.project_counter}\n
          #                #{download_release.version} #{download_release.release_counter}\n
          #                #{download_file.name} #{download_file.path} #{download_file.file_counter}"
          redirect_to "http://dev.openfoundry.org/download/#{params[:project_name]}/#{params[:release_name]}/#{params[:file_name]}"
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
