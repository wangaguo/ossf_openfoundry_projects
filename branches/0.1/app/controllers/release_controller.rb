class ReleaseController < ApplicationController
    
  def index
    list
    render :action => :list
  end
  
  #show all releases with given project id
  def show
     @release = Release.find(params[:id])
     @files = @release.fileentity
  end
  
  #list all release for a given :project_id
  def list
    @project_id = params[:project_id]
    @releases = Release.find :all,
      :conditions => "project_id = #{params[:project_id]}"
  end
  
  def create
    if request.post?
      r=Release.new(:attributes => params[:release] )
      if r.save!
        flash.now[:message] = 'Create New Release Successfully!'
        redirect_to :action => :list
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

  def destory
    if request.post?
      r=Release.find(params[:id])
      r.destroy unless r.nil?
    end
    redirect_to :action => :list, :project_id => params[:project_id]
  end

  def edit
    if request.get?
      @release = Release.find(params[:id])
    else 
      #update!
    end
  end
  
  def uploadfiles
    pattern = params[:move]
    pattern ||= '/tmp'
    @current_dir = pattern
    
    #加上File match mark "**", see File:fnmatch, Dir.glob
    pattern = File.join pattern,'**'
    
    @release = Release.find params[:release_id]
    @project = Project.find params[:project_id]
    
    @uploadfiles = []
    @uploaddirs = []
    Dir.glob(pattern){ |file|
      if File.directory?(file)
        @uploaddirs.push file
      else
        @uploadfiles.push file
      end
    }
    
    #為viewer準備上層dir
    Dir.chdir @current_dir+'/..' do
      @upper_dir = Dir.pwd
    end
    
    #不套用layout
    if params[:layout] == 'false'
      render :layout => false   
    end
  end
  
  def addfiles
    #if request.post?
      r = Release.find params[:release_id]
      return if r.nil?
      files = params[:uploadfiles].collect { |path| make_file_entity path }
      r.fileentity << files
      r.save
      flash.now[:message] = 'Your files have been added to Release!'
      
      uploadfiles
      render :layout =>false, :action => :uploadfiles
    #else
      #TODO wrong argument!
    #end
  end
  
  private
  def make_file_entity(path)
    unless ret=Fileentity.find_by_path(path).nil?
      ret
    else
      #TODO collect meta info for FILE
      Fileentity.create ( :attributes => {:path => path} )
    end
  end
  
end
