class SurveyController < ApplicationController
  layout 'application'
  #see lib/permission_table.rb
  before_filter :find_resource_project
  before_filter :check_permission
  #before_filter :default_module_name
  
  def find_resource_project
    @project = Project.find_by_id(params['project_id']) if params['project_id']
    @project ||= Project.find_by_id(params['id']) if params['id']
  end
  private :find_resource_project

  def review
    unless Project.exists?(params[:id])
      render :text => 'Project not found'
    end
    @project = Project.find(params[:id])
    params[:project_id]=@project.id

    #show file
    if params[:id] and params[:version] and params[:path] 
      @downloaders = Downloader.file_reviews params[:id],params[:version],params[:path]
      #render :text => "#{@downloaders.length}" 
    end

    #show release
    if params[:id] and params[:version] and !params[:path] 
      @downloaders = Downloader.release_reviews params[:id],params[:version]
      #render :text => 'release!'
    end

    #show project
    if params[:id] and !params[:version] and !params[:path] 
      #render :text => 'project!'
      @downloaders = Downloader.project_reviews(params[:id])
    end
  end

  def show
    project_id = params[:project_id]
    unless Project.exists?(project_id)
      render :text => 'Project not found'
    end
    @project = Project.find(project_id, :include => [Release, Fileentity])
    files = []
    resource = "0"*11
    prompt = ''
    params['id'].split('_').each{|id| 
      f=Fileentity.find_by_id(id, :include => Survey)
      if f
        files << f
        if f.survey
           resource,prompt = Survey.merge(f.survey, [resource, prompt]) 
        end
      end
    }
    render :file => 'app/views/survey/show.html.erb', :layout => false,
      :locals => {
        :files => files, :resource => resource, :prompt => prompt}
  end

  def delete
    #given :fileentity_ids
    params['id'].split('_').each do |id|
      if f=Fileentity.find_by_id(id)
        f.survey.destroy if f.survey
        f.save
      end
    end
    redirect_to :action => :show
  end

  def update
    #given :fileentity_ids #Array, :resource #String
    #will update/create survey for fileendity_id and set resource
    fileenfity_ids = params['id'].split('_')
    resource = params['resource'].ljust(11,'0')
    prompt = params['prompt']

    fileenfity_ids.each do |id| 
      if f=Fileentity.find_by_id(id)
        f.survey.destroy if f.survey
        f.survey = Survey.create(:resource => resource, :prompt => prompt)
        f.save
      end
    end
    redirect_to :action => :show
  end

  def index
    project_id = params[:project_id]
    unless Project.exists?(project_id)
      render :text => 'Project not found'
    end
    @project = Project.find(project_id, :include => [Release, Fileentity])
    @releases = @project.releases
    @resource = '0'*11
    #render :text => ERB::Util.html_escape(@releases.inspect)
    #render :file => 'app/views/survey/show.html.erb', :layout => 'application'
  end
  
  def apply
    check_download_consistancy
    unless @error_msg.empty?
      render :text => CGI.escapeHTML("#{@project} #{@release} #{@file}")
      return  
    end
    @survey = Survey.find_by_id params['id']
    if request.method == :get
      @downloader = Downloader.new(params['downloader'])
    elsif request.method == :post
      #TODO login user?
      
      #goto download_path if no file in session! 
      unless session[:saved_download_path] 
        #missing filename in session
        #back to 'download'
        redirect_to(download1_path @project)
        return
      end

      #validate fields...
      @downloader = Downloader.new(params['downloader'])
      unless @downloader.check_mandatory(@survey.resource)
        flash[:warning] = s_('Survey|You have to fill the REQUIRED fileds.')
        return
      end
      @downloader.user = current_user
      @downloader.project = @project
      @downloader.fileentity = @file
      @downloader.release = @release
      @downloader.save
      redirect_to(download1_path @project)
      return
    end

  end
end
