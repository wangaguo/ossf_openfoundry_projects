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
    
    #Release
    desc = ['Manage Releases']
      Function.create :name => "release", :module => 'Release', 
        :description => desc[0]
    
    #News
    desc = ['Manage News']
      Function.create :name => "news", :module => 'News', 
        :description => desc[0]
        
    #Job
    desc = ['Manage Help Wanted']
      Function.create :name => "job", :module => 'Job', 
        :description => desc[0]
        
    #Citation
    desc = ['Manage Citations']
      Function.create :name => "citation", :module => 'Citation', 
        :description => desc[0]
        
    #Reference
    desc = ['Manage References']
      Function.create :name => "reference", :module => 'Reference', 
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
    User.create :login => 'guest', :email => '',:verified => 0
    u = User.create :login => 'root', :email => '',:verified => 1, :salted_password => ''.crypt('$1$')
    r = Role.create :name => 'site_admin'
    r.users << u
    r.save!
    r = Role.create :name => 'project_reviewer'
    r.users << u
    r.save!	
  end

  def self.down
    Function.delete_all
    User.delete_all
    Role.delete_all
  end
end
