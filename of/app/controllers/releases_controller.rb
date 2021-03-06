class ReleasesController < ApplicationController
  find_resources(:parent => 'project', 
    :child => 'release', 
    :parent_id_method => 'project_id')
  layout 'module'

  #see lib/permission_table.rb
  #before_filter :login_required, :only => [ :show ]
  before_filter :check_permission
  before_filter :default_module_name

  def default_module_name
    @module_name = _("Release")
  end
  
  def index
    if params[:project_id].nil?
      respond_to do |f|
        f.html { redirect_to root_path + 'releases/latest' }
        f.json { render :json => @releases.map { |r| 
          {:id => r.id, :name => r.version} 
        } }
      end
    else
      list
      respond_to do |f|
        f.html { render :action => :list }
        f.json { render :json => @releases.map { |r| 
          {:id => r.id, :name => r.version} 
        } }
      end
    end
  end
  
  #show all releases with given project id
  def show
     #@project_id = params[:project_id]
     #@release = Release.find(params[:id])
     #@files = @release.fileentity
    @release = Release.find params[:id]
    if @release.lock? == false
      uploadfiles
      render :action => :uploadfiles
    else
      flash[:warning] = _('nsc.locked')
      redirect_to project_releases_path(params[:project_id])
    end
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
    @module_name = _('release_Edit')
    @project_id = params[:project_id]
    @releases = Release.find :all,
      :conditions => "project_id = #{params[:project_id]}", :order => 'due desc'
    if params[:layout] == 'false'
      render :layout => false   
    end
  end

  def top
    @module_name = _("Top Downloads")
    releases = Release.top_download.paginate(:page => params[:page], :per_page => 50)
    if(params[:page].nil?)
      params[:page] = 1
    end
    @page = params[:page].to_i
    if releases.out_of_bounds?
      releases = Release.paginate(:page => 1, :per_page => 50)
      @page = 1
    end
    render(:template => 'releases/_top_download_list', :locals => { :releases => releases, :page => @page })
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

    render(:template => 'releases/_top_download_list', :locals => { :releases => releases, :page => @page })
  end
  
  def download
    @module_name = _("Downloads")
    @project_id = params[:project_id]
    @project_name = Project.find(params[:project_id]).name
    @releases = Release.paginate :page => params[:page], :per_page => 5,
      :conditions => "project_id = #{params[:project_id]} AND status = 1", :order => "due desc" 
    download_statics = DownloadStatic.select("file,SUM(count) as count_all").where("project='#{@project_name}'").group("file")
    @statics = {}
    download_statics.each do |v|
                       @statics.merge!(v.file=>v.count_all)
               end
    #check if user has survey permission
    @permissions = []
    if fpermit?('survey', @project_id)
      @permissions << :survey
    end

    #for IE activeX download redirect
#    @rdr_download_url = session[:tmp_download_path] if session[:tmp_download_path] and request.referer.nil? and session[:tmp_download_path].include? "#{OPENFOUNDRY_HOST}#{root_path}/download/#{@project_name}" 
#    session[:tmp_download_path] = nil

    #use session to rememer FILE after SURVEY form filled...
    if session[:saved_download_path]
      @rdr_download_url = "#{request.protocol}#{OPENFOUNDRY_HOST}#{root_path}/download/#{session[:saved_download_path]}" 
      session[:saved_download_path] = nil
#      session[:tmp_download_path] = @rdr_download_url
    end
  end

  def create
    if request.post?
      @release = Release.new(:attributes => params[:release] )
      @release.project_id = params[:project_id]
      if @project.releases.find_by_version("#{params[:release][:version]}").nil?
        if @release.save
          flash[:message] = 'Create New Release Successfully!'
          redirect_to(project_releases_path(:project_id => params[:project_id])) 
        else
          flash[:warning] = 'Invalid version format!'
          new
        end
      else
        flash.now[:warning] = 'Version is exists!'
        new
      end
    end
  end
  
  def new
    @module_name = _('release_New')
    if request.get?
      @release = Release.new
      @release.status = 0
    end
    @release_status = { Release.status_to_s(0) => 0, Release.status_to_s(1) => 1}
    render :template => 'releases/new'
  end

  def delete
    if request.post?
      r=Release.find_by_id(params[:id])
      if r.lock? == false
        dest_dir = "#{Project::PROJECT_DOWNLOAD_PATH}/#{r.project.name}/#{r.version}"
        system("/home/openfoundry/bin/remove_release_files", dest_dir) unless r.nil?
        r.destroy unless r.nil?
      end
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

  def web_upload
    for i in 1..5
      file = 'upload_file_'+i.to_s
      if !params[file].nil?
        upload_an_file(params[file])
      end
    end
    redirect_to url_for(:project_id => params[:project_id],
      :action => :show, :id => params[:id])
  end

  def upload_an_file(uploaded_file)
    save_as = File.join(Project::PROJECT_UPLOAD_PATH, @project.name , 'upload', uploaded_file.original_filename)

    File.open( save_as.to_s, 'w' ) do |file|
      file.write( uploaded_file.read )
    end
    return true
  end

  def delete_files
    if !params[:uploadfiles].nil? 
      params[:uploadfiles].each do |f|
        file_path = "#{Project::PROJECT_UPLOAD_PATH}/#{@project.name}/upload/#{f}"
        File.delete(file_path) if File.exist?(file_path)
      end
    end
    reload
  end
  
  #用link_to_remote呼叫 將檔案加入專案發佈中
  def addfiles
    def bad_file(x)
      x == '' or x == ".." or x =~ /\//
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
        flash[:error] = _( 'Bad project name' ) + ": #{ project_name }"
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
      flash[:error] = _( 'Bad version' ) + ": #{ r.version }"
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

        r.fileentity << make_file_entity(params[:id], basename, File.size(src_path))
        if system("/home/openfoundry/bin/move_upload_files2", src_path, dest_dir) == true
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
    file = Fileentity.find_by_id params[:removefile_id]
    dest_file = "#{Project::PROJECT_DOWNLOAD_PATH}/#{r.project.name}/#{r.version}/#{file.path}"
    system("/home/openfoundry/bin/remove_release_files", dest_file) unless file.nil?
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
    respond_to do |format|
      format.html {render :partial => 'file_edit', :layout => false, :local => @file}
      format.js
    end
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

  def new_releases
    project = Project.find(params[:project_id])
    release = Release.find(params[:id])
    if !release.nil? && project == release.project
      @news = News.new
      @news.subject = "New release: " + release.version
      release.fileentity.each do |file|
        @news.description += "* #{file.path} (#{file.description})\n"
      end
      @news.description += project_download_url(project, :host => OPENFOUNDRY_HOST)
      @news.status = News::STATUS[:Disabled]
    else
      flash[:error] = _('No this release.')
      redirect_to(request.referer || '/')
    end
  end

#  def top_download_feed
#    top_releases = Release.find(:all, :group => 'project_id', :include => [:project], :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "MAX(release_counter) DESC", :limit => 10)
#
#    feed_options = {
#      :feed => {
#        :title       => _("OpenFoundry: Top Download"),
#        :description => _("Top download on OpenFoundry"),
#        :link        => 'of.openfoundry.org',
#        :language    => 'UTF-8'
#      },
#      :item => {
#        :title => lambda { |r| "#{r.project.summary} #{r.version}"},
#        :description => lambda {|r| "#{r.project.description}"},
#        :link => lambda { |r| download1_url(:project_id => r.project.id)+"##{r.version}" }
#      }
#    }
#    respond_to do |format|
#      format.rss { render_rss_feed_for top_releases, feed_options }
#      format.xml { render_atom_feed_for top_releases, feed_options }
#    end
#  end

#  def new_release_feed
#    new_release = Release.find(:all, :include => [:project], :conditions => 'releases.status = 1 AND ' + Project.in_used_projects(:alias => "projects"), :order => "releases.created_at desc", :limit => 10)
#
#    feed_options = {
#      :feed => {
#        :title       => _("OpenFoundry: Latest Releases"),
#        :description => _("Latest releases on OpenFoundry"),
#        :link        => 'of.openfoundry.org',
#        :language    => 'UTF-8'
#      },
#      :item => {
#        :title => lambda { |r| "#{r.project.summary} #{r.version}"},
#        :description => lambda {|r| "#{r.project.description}"},
#        :link => lambda { |r| download1_url(:project_id => r.project.id)+"##{r.version}" }
#      }
#    }
#    respond_to do |format|
#      format.rss { render_rss_feed_for new_release, feed_options }
#      format.xml { render_atom_feed_for new_release, feed_options }
#    end
#  end

  def files
    release = Release.find(params[:id])
    render :json => release.fileentity.map { |f| {:id => f.id, :name => f.path} }
  end

  def toggle_lock
    if current_user().has_role?('nsc_admin') 
      release = Release.find(params[:id])
      if release.lock?
        release.unlock_at = nil
      else
        release.unlock_at = "#{(Date.today.year+NSC_UNLOCK_YEAR.to_i)}/#{NSC_UNLOCK_DATE}"
      end
      release.save! 
    end

    redirect_to project_download_path(params[:project_id])
  end

  private
  
  #建立檔案的database entry, 會連結到外部ftp hook
  def make_file_entity(release_id, path, size)
    unless ( ret=Fileentity.find_by_release_id_and_path(release_id, path) ).nil?
      ret
    else
      #TODO collect meta info for FILE, move FILE
      Fileentity.create( :attributes => {:path => path, :size => size} )
    end
  end
end
