class AddSiteData < ActiveRecord::Migration
  def self.up   
    #Project
    %w(info member).each do |name|
      Function.create :name => "project_#{name}", :module => 'Project'
    end
    
    #Role
    %w(new edit delete).each do |name|
      Function.create :name => "role_#{name}", :module => 'Role'
    end
    
    #Relesae
    %w(new edit delete view).each do |name|
      Function.create :name => "release_#{name}", :module => 'Release'
    end
    
    #News
    %w(post edit delete view).each do |name|
      Function.create :name => "news_#{name}", :module => 'News'
    end
    
    #Wiki
    %w(new edit delete view).each do |name|
      Function.create :name => "wiki_#{name}", :module => 'Wiki'
    end
    
    #forums
    %w(post view archive).each do |name|
      Function.create :name => "forums_#{name}", :module => 'Forums'
    end
    
    #VCS
    %w(svn_import cvs_import svn_ci cvs_ci).each do |name|
      Function.create :name => "vcs_#{name}", :module => 'Vcs'
    end
    
    #FTP
    Function.create :name => 'ftp_login', :module => 'ftp', :description => 'ftp access'
  end

  def self.down
  end
end
