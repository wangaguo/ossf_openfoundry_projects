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
    desc = ['Edit Role Permissions']
    #Role
    %w(edit).each_with_index do |name, i|
      Function.create :name => "role_#{name}", :module => 'Role', 
        :description => desc[i]
    end
    
    #Relesae
    desc = ['Manage Releases']
      Function.create :name => "release", :module => 'Release', 
        :description => desc[0]
    
    #News
    desc = ['Manage News']
      Function.create :name => "news", :module => 'News', 
        :description => desc[0]
    
    #Kwiki
    desc = ['Manage Kwiki Pages']
    %w(manage).each_with_index do |name, i|
      Function.create :name => "kwiki_#{name}", :module => 'Wiki', 
        :description => desc[i]
    end
    
    #Issue Tracker
    desc = ['Set As Tracker Admin', 'Set As Tracker CC']
    %w(admin member).each_with_index do |name, i|
      Function.create :name => "rt_#{name}", :module => 'Tracker', 
        :description => desc[i]
    end
    
    #Sympa
    desc = ['Manage Sympa Mailing Lists']
    %w(manage).each_with_index do |name, i|
      Function.create :name => "sympa_#{name}", :module => 'Forums', 
        :description => desc[i]
    end
    
    #VCS
    desc = ['Commit Changes']
    %w(commit).each_with_index do |name, i|
      Function.create :name => "vcs_#{name}", :module => 'Vcs', 
        :description => desc[i]
    end
    
    #FTP
    Function.create :name => 'ftp_access', :module => 'Ftp', :description => 'Ftp Access'
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
