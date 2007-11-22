class ReleaseController < ApplicationController
    
  def index
    render :action => :list
  end
  
  #show all releases with given project id
  def show
     @release = Release.find(params[:id])
     @files = @release.fileentity
  end
  
  #list all release for a given :project_id
  def list
    @releases = Release.find :all,
      :conditions => "project_id = #{params[:id]}"
  end
  
  def new
    if request.get?
      @relesae = Release.new
      render
    else
      #new a release
    end
  end

  def delete
    if request.delete?
      r=Release.find(params[:id])
      r.delete unless r.nil?  
    end
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
    
    #把目錄下的所有東西撈出來, 目錄以'd'表示, 檔案用'f'
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
  
end
