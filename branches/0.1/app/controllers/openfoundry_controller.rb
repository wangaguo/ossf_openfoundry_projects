require "rubygems"
require "json"

class OpenfoundryController < ApplicationController

  def index
  end

  # TODO: optimize!!!!!!!!!!
  def authentication_authorization
    #self.class.layout(nil)
    session_id, project_unixname = params[:SID], params[:projectUnixName]
    if the_session = Session.find_by_session_id(session_id)
      the_session_data = Marshal.load(Base64.decode64(the_session.data))
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
    data = {
      :projects => Project.find_all().map { |p| { :Id => p.id, :ProjectName => p.projectname , :UnixName => p.unixname } },
      :users => User.find_all().map { |u| { :Id => u.id, :Name => u.login, :Email => u.email } },
      :relations => {
        :admin => Project.find_all().inject([]) { |all, p| all + p.admins().map { |u| [p.id, u.id] } },
        :member => Project.find_all().inject([]) { |all, p| all + p.members().map { |u| [p.id, u.id] } }
      }
    }
    render :text => data.to_json, :layout => false
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
end
