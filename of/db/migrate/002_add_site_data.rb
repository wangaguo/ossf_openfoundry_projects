class AddSiteData < ActiveRecord::Migration
  def self.up  
    #--------------
    #建立權限
    #--------------        
    #Project
    desc = ['Modify Project Information', 'Add/Remove Project Members']
    %w(info member).each_with_index do |name, i|
      Function.create :name => "project_#{name}", :module => 'Project', 
        :description => desc[i]
    end
    desc = ['Create a New Role', 'Edit Role Permissions', 'Delete Roles']
    #Role
    %w(new edit delete).each_with_index do |name, i|
      Function.create :name => "role_#{name}", :module => 'Role', 
        :description => desc[i]
    end
    
    #Relesae
    desc = ['Add new Release', 'Edit Releases', 'Delete Release', 'View Release Details']
    %w(new edit delete view).each_with_index do |name, i|
      Function.create :name => "release_#{name}", :module => 'Release', 
        :description => desc[i]
    end
    
    #News
    desc = ['Post new Release', 'Edit News', 'Delete News', 'View News Details']
    %w(post edit delete view).each_with_index do |name, i|
      Function.create :name => "news_#{name}", :module => 'News', 
        :description => desc[i]
    end
    
    #Wiki
    desc = ['Add Wiki Page', 'Edit Wiki Pages', 'Delete Wiki Page', 'View Page Details']
    %w(new edit delete view).each_with_index do |name, i|
      Function.create :name => "wiki_#{name}", :module => 'Wiki', 
        :description => desc[i]
    end
    
    #Issue Tracker
    desc = ['Create New Ticket', 'View Ticket Details', 'Assign Ticket']
    %w(new edit assign).each_with_index do |name, i|
      Function.create :name => "rt_#{name}", :module => 'rt', 
        :description => desc[i]
    end
    
    #forums
    desc = ['Post Messages', 'View List Details', 'Access Message Archives']
    %w(post view archive).each_with_index do |name, i|
      Function.create :name => "forums_#{name}", :module => 'Forums', 
        :description => desc[i]
    end
    
    #VCS
    desc = ['SVN import', 'CVS import', 'SVN commit', 'CVS commit']
    %w(svn_import cvs_import svn_ci cvs_ci).each_with_index do |name, i|
      Function.create :name => "vcs_#{name}", :module => 'Vcs', 
        :description => desc[i]
    end
    
    #FTP
    Function.create :name => 'ftp_login', :module => 'ftp', :description => 'Ftp Access'
    #--------------
    #建立User 
    #--------------
    User.create :login => 'root', :email => 'contact@openfoundry.org',:verified => 0
    User.create :login => 'guest', :email => 'contact@openfoundry.org',:verified => 0

    #--------------
    #建立Project
    #--------------
    index = 1000
    %w(openfoundry testsvn testsympa testrt testftp testweb testcvs sandbox test).each do |summary|
      Project.create( :id => index,
                      :name => summary, 
                      :summary => "#{summary}",
                      :rationale => "#{summary}",
                      :description => "",
                      :contactinfo => "contact@#{summary}.openfoundry.org",
                      :maturity => "under construltion",
                      :license => "BSD",
                      :contentlicense => "GPL",
                      :platform => "FreeBSD",
                      :programminglanguage => "ruby",
                      :intendedaudience => "end user",
                      :creator => 1,
                      :status => 3,
                      :vcs => "svn",
                      :icon => 5
      )
      index+=1
    end
  end

  def self.down
    Function.delete_all
  end
end
