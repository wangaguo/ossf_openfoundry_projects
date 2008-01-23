class ReleasesController < ApplicationController
  find_resources :parent => 'project', 
    :child => 'release', 
    :parent_id_method => 'project_id'
  def index
    list
    render :action => :list
  end
  
  #show all releases with given project id
  def show
     @project_id = params[:project_id]
     @release = Release.find(params[:id])
     @files = @release.fileentity
  end
  
  #list all release for a given :project_id
  def list
    @project_id = params[:project_id]
    @releases = Release.find :all,
      :conditions => "project_id = #{params[:project_id]}"
    if params[:layout] == 'false'
      render :layout => false   
    end
  end
  
  def create
    if request.post?
      r=Release.new(:attributes => params[:release] )
      r.project_id = params[:project_id]
      if r.save!
        flash.now[:message] = 'Create New Release Successfully!'
        redirect_to(url_for :project_id => params[:project_id], :action => :index) 
      else
        flash.now[:message] = 'Faild to Create New Release!'
      end
    end
  end
  
  def new
    if request.get?
      @release = Release.new
    end
  end

  def delete
    if request.post?
      r=Release.find(params[:id])
      r.destroy unless r.nil?
    end
    redirect_to(url_for :project_id => params[:project_id], :action => :index)
  end
  
  def update
    #if request.post?
      r=Release.find params[:id]
      r.attributes= params[:release]
      if r.save!
        flash[:notice] = 'Edit Release Successfully!'
        redirect_to(url_for :project_id => params[:project_id],
          :action => :show, :id => params[:id]
        ) 
      else
        flash.now[:message] = 'Faild to Update Release!'
      end
    #end
#    flash.now[:message] = 'Faild to Update Release!'
#    redirect_to(url_for :project_id => params[:project_id],
#      :action => :edit, :id => params[:id]
#    ) 
  end
  
  def edit
    if request.get?
      @release = Release.find(params[:id])
      @project_id = params[:project_id]
    end
  end
  
  def uploadfiles
    pattern = params[:move]
    project_name = Project.find(params[:project_id]).unixname
    
    Release::build_path(project_name, params[:project_id])
    
    if pattern.nil?
      pattern = "#{project_name}"
    end
    
    #upload root, can't go upper
    root = "#{Project::PROJECT_UPLOAD_PATH}"

    path = File.join(root, pattern)
    
    #protect system...from hacking
    if !File.exist?(path) or #illegal?
      !(File.expand_path(path) =~ /^#{root}\/#{project_name}/) #go upper?
      #sorry, back to upload home
      pattern = "#{project_name}"
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
    #if request.post?
      r = Release.find params[:id]
      return if r.nil?
      files = params[:uploadfiles].collect { |path| make_file_entity path }
      r.fileentity << files
      r.save
      flash[:notice] = 'Your files have been added to Release!'
     
      #move file from upload to downlad area
      project_name = Project.find(params[:project_id]).unixname
      release_tag_path = "#{Project::PROJECT_DOWNLOAD_PATH}/#{project_name}/#{r.name}"
      Dir.mkdir(release_tag_path) unless File.exist?(release_tag_path)
      `cd #{Project::PROJECT_UPLOAD_PATH}/#{project_name};mv #{files.collect{|f| f.path}.join(' ')} #{release_tag_path}`

      redirect_to url_for(:project_id => params[:project_id], 
        :action => :uploadfiles, :id => r.id, :layout =>'false')
    #else
      #TODO wrong argument!
    #end
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
  
  private
  
  #建立檔案的database entry, 會連結到外部ftp hook
  def make_file_entity(path)
    unless ( ret=Fileentity.find_by_path(path) ).nil?
      ret
    else
      #TODO collect meta info for FILE, move FILE
      Fileentity.create ( :attributes => {:path => path} )
      
      
    end
  end
  
end
