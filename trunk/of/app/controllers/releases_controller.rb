class ReleasesController < ApplicationController
  find_resources(:parent => 'project', 
    :child => 'release', 
    :parent_id_method => 'project_id')
  layout 'module'
  #see lib/permission_table.rb
  before_filter :check_permission
  before_filter :default_module_name

  def default_module_name
    @module_name = _("Release")
  end
  
  def index
    list
    render :action => :list
  end
  
  #show all releases with given project id
  def show
     #@project_id = params[:project_id]
     #@release = Release.find(params[:id])
     #@files = @release.fileentity
    uploadfiles
    render :action => :uploadfiles
  end
  
  def reload
     #@project_id = params[:project_id]
     #@release = Release.find(params[:id])
     #@files = @release.fileentity
    uploadfiles
    render :action => :uploadfiles, :layout=> false
  end
  
  #list all release for a given :project_id
  def list
    @project_id = params[:project_id]
    @releases = Release.find :all,
      :conditions => "project_id = #{params[:project_id]}", :order => 'due desc'
    if params[:layout] == 'false'
      render :layout => false   
    end
  end

  def top
    @module_name = _("Top Downloads")
    releases = Release.find(:all, :include => [:project], :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "release_counter desc", :limit => 100).paginate(:page => params[:page], :per_page => 100)
    if(params[:page].nil?)
      params[:page] = 1
    end
    @page = params[:page].to_i
    if releases.out_of_bounds?
      releases = Release.paginate(:page => 1, :per_page => 100)
      @page = 1
    end
    render(:partial => 'top_download_list', :layout => true, :locals => { :releases => releases, :page => @page })
  end

  def latest
    @module_name = _("Latest Releases")
    releases = Release.find(:all, :include => [:project], :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "releases.created_at desc", :limit => 100).paginate(:page => params[:page], :per_page => 100)
    if(params[:page].nil?)
      params[:page] = 1
    end
    @page = params[:page].to_i
    if releases.out_of_bounds?
      releases = Release.paginate(:page => 1, :per_page => 100)
      @page = 1
    end
    render(:partial => 'top_download_list', :layout => true, :locals => { :releases => releases, :page => @page })
  end
  
  def download
    @module_name = _("Downloads")
    @project_id = params[:project_id]
    @project_name = Project.find(params[:project_id]).name
    @releases = Release.find :all,
      :conditions => "project_id = #{params[:project_id]} AND status = 1", :order => "created_at desc" 
  end
  
  def create
    if request.post?
      r=Release.new(:attributes => params[:release] )
      r.project_id = params[:project_id]
      if r.save
        flash[:message] = 'Create New Release Successfully!'
        redirect_to(url_for(:project_id => params[:project_id], :action => :index)) 
      else
        #flash[:message] = 'Faild to Create New Release!'
        flash[:warning] = 'Invalid version format!'
        redirect_to(new_release_url(:project_id => params[:project_id], :action => :new)) 
      end
    end
  end
  
  def new
    if request.get?
      @release = Release.new
      @release.status = 0
      @release_status = { Release.status_to_s(0) => 0, Release.status_to_s(1) => 1}
    end
  end

  def delete
    if request.post?
      r=Release.find(params[:id])
      r.destroy unless r.nil?
    end
    redirect_to(url_for(:project_id => params[:project_id], :action => :index))
  end
  
  def updaterelease
    #if request.post?
      @release =Release.find_by_id params[:id]
      @release.attributes= params[:release]
      if @release.save!
        flash[:notice] = 'Edit Release Successfully!'
  #      redirect_to(url_for(:project_id => params[:project_id],
  #        :action => :show, :id => params[:id]
  #      )) 
        render :partial => 'release_view', :layout => false
      else
        flash.now[:message] = 'Faild to Update Release!'
      end
    #end
#    flash.now[:message] = 'Faild to Update Release!'
#    redirect_to(url_for :project_id => params[:project_id],
#      :action => :edit, :id => params[:id]
#    ) 
  end
  
  def uploadfiles
    pattern = params[:move]
    project_name = Project.find(params[:project_id]).name
    
    Release::build_path(project_name, params[:project_id])
    
    if pattern.nil?
      pattern = "#{project_name}/upload"
    end
    
    #upload root, can't go upper
    root = "#{Project::PROJECT_UPLOAD_PATH}"

    path = File.join(root, pattern)
    
    #protect system...from hacking
    if !File.exist?(path) or #illegal?
      !(File.expand_path(path) =~ /^#{root}\/#{project_name}\/upload/) #go upper?
      #sorry, back to upload home
      pattern = "#{project_name}/upload"
      path = File.join(root, pattern) 
    end
    
    #expand_path and extract current releative dir
    pattern = File.expand_path(path).match(/^#{root}\/(.*)/)[1]

    @current_dir = pattern
    @release = Release.find params[:id]
    @project = Project.find params[:project_id]
    
    @uploadfiles = []
    @uploaddirs = []
    #加上File match mark "**", see File:fnmatch, Dir.glob
    Dir.glob(File.join(path,"**")){ |file|
      if File.directory?(file)
        @uploaddirs.push File.basename(file)
      else
        @uploadfiles.push File.basename(file)
      end
    }
    

    
    #不套用layout 發生在addfiles removefiles return時
    if params[:layout] == 'false'
      render :layout => false   
    end
  end
  
  #用link_to_remote呼叫 將檔案加入專案發佈中
  def addfiles
    def bad_file(x)
      x == ".." or x =~ /\//
    end

    pass = true
    if not r = Release.find_by_id(params[:id])
      flash[:error] = _('Release id not found!')
      pass = false
    end
    
    if project = Project.find_by_id(params[:project_id])
      project_name = project.name
      # paranoid ...
      if bad_file(project_name)
        flash[:error] = _('Bad project name: #{project_name}')
        pass = false
      end
    else
      flash[:error] = _('Project id not found!')
      pass = false
    end

    if not params[:uploadfiles]
      flash[:error] = _('You doesn\'t select any files!')
      pass = false
    end

    # paranoid ...
    if bad_file(r.version)
      flash[:error] = _('Bad version: #{r.version}')
      pass = false
    end

    if pass
      dest_dir = "#{Project::PROJECT_DOWNLOAD_PATH}/#{project_name}/#{r.version}"

      added = false

      # uploadfiles contains only file name (basename)
      params[:uploadfiles].each do |basename|
        next if bad_file(basename)

        src_path = "#{Project::PROJECT_UPLOAD_PATH}/#{project_name}/upload/#{basename}"
        next if not File.exist?(src_path)

        r.fileentity << make_file_entity(basename, File.size(src_path))
        
        if system("/home/openfoundry/bin/move_upload_files2", src_path, dest_dir) == 0
          added = true
        end
      end

      if added 
        r.save
        flash[:notice] = _('Your files have been added to Release!')
      else
        flash[:error] = _('No file has been added!')
      end
    end

    redirect_to url_for(:project_id => params[:project_id], 
      :action => :uploadfiles, :id => r.id, :layout =>'false')
  end
  
  #用link_to_remote呼叫 將檔案從專案發佈中移除(非刪除)
  def removefile
    r = Release.find params[:id]
    return if r.nil?
    file = Fileentity.find params[:removefile_id]
    r.fileentity.delete file
    r.save
    flash[:notice] = 'Your files have been remove from Release!'
    
    redirect_to url_for(:project_id => params[:project_id], 
      :action => :uploadfiles, :id => r.id, :layout =>'false')
  end

  def editrelease
    @release = Release.find(params[:id])
    @project_id = params[:project_id]
    @release_status = { Release.status_to_s(0) => 0, Release.status_to_s(1) => 1}
    render :partial => 'release_edit', :layout => false
  end

  def viewrelease
    @release = Release.find_by_id(params[:id])
    @project_id = params[:project_id]
    @release_status = { Release.status_to_s(0) => 0, Release.status_to_s(1) => 1}
    render :partial => 'release_view', :layout => false
  end

  #用link_to_remote呼叫 編輯檔案
  def editfile
    r = Release.find params[:id]
    return if r.nil?
    @file = Fileentity.find_by_id params[:editfile_id]
    render :partial => 'file_edit', :layout => false, :local => @file
  end
  
  def viewfile
    @release = Release.find_by_id(params[:id])
    @project_id = params[:project_id]
    @file = Fileentity.find_by_id params[:editfile_id]
     render :partial => 'file_view', :layout => false
  end

  def updatefile
    file = Fileentity.find params[:updatefile_id]
    file.name = params[:name]
    file.description = params[:description]
    file.meta = params[:meta]
    file.save
    flash[:notice] = 'Your files have been updated from Release!'
    
    redirect_to url_for(:project_id => params[:project_id], 
      :action => :uploadfiles, :id => params[:id], :layout =>'false')
  end

  private
  
  #建立檔案的database entry, 會連結到外部ftp hook
  def make_file_entity(path, size)
    unless ( ret=Fileentity.find_by_path(path) ).nil?
      ret
    else
      #TODO collect meta info for FILE, move FILE
      Fileentity.create( :attributes => {:path => path, :size => size} )
    end
  end

end
