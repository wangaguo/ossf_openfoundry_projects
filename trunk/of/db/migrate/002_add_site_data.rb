class AddSiteData < ActiveRecord::Migration
  def self.up   
    #Project
    desc = ['Modify Project Information', 'Add/Remove Project Members']
    %w(info member).each_with_index do |name, i|
      Function.create :name => "project_#{name}", :module => 'Project', 
        :description => desc[i]
    end
    desc = ['Create a New Role', 'Edit Role Permissions', 'Delete Roles']
    #Role
    %w(new edit delete).each do |name|
      Function.create :name => "role_#{name}", :module => 'Role', 
        :description => desc[i]
    end
    
    #Relesae
    desc = ['Add new Release', 'Edit Releases', 'Delete Release', 'View Release Details']
    %w(new edit delete view).each do |name|
      Function.create :name => "release_#{name}", :module => 'Release', 
        :description => desc[i]
    end
    
    #News
    desc = ['Post new Release', 'Edit News', 'Delete News', 'View News Details']
    %w(post edit delete view).each do |name|
      Function.create :name => "news_#{name}", :module => 'News', 
        :description => desc[i]
    end
    
    #Wiki
    desc = ['Add Wiki Page', 'Edit Wiki Pages', 'Delete Wiki Page', 'View Page Details']
    %w(new edit delete view).each do |name|
      Function.create :name => "wiki_#{name}", :module => 'Wiki', 
        :description => desc[i]
    end
    
    #forums
    desc = ['Post Messages', 'View List Details', 'Access Message Archives']
    %w(post view archive).each do |name|
      Function.create :name => "forums_#{name}", :module => 'Forums', 
        :description => desc[i]
    end
    
    #VCS
    desc = ['do SVN import', 'do CVS import', 'do SVN commit', 'do CVS commit']
    %w(svn_import cvs_import svn_ci cvs_ci).each do |name|
      Function.create :name => "vcs_#{name}", :module => 'Vcs', 
        :description => desc[i]
    end
    
    #FTP
    Function.create :name => 'ftp_login', :module => 'ftp', :description => 'Ftp Access'
  end

  def self.down
  end
end
