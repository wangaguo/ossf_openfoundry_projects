ActionController::Routing::Routes.draw do |map|

  map.root :controller => 'openfoundry'
  #####################
  # API!!
  #####################
  map.resource :api,
    :controller => :api, :only => [:user,:project],
    :member => {:user => :get, :project => :get}
  #####################
  #administration:
  #####################
  map.connect 'site_admin', :controller => 'site_admin/site_admin'

  map.namespace :site_admin do |admin|
    admin.resources :projects,
                    :member => {:change_status_form => :any,
                                :list => :any,
                                :projects_upload => :any
                                }
  end
  map.project_jobs '/projects/jobs', :controller => 'jobs', :action => 'project_jobs'
  map.project_news '/projects/news', :controller => 'news', :action => 'project_news'

  #####################
  #downloaders' reviews: for project, release, and file
  #####################
  map.file_review '/projects/:id/releases/:version/files/:path/reviews',
                      :controller => 'survey', :action => 'review',
                      :requirements => {:path => /.+/, :version => /.+/}
  map.release_review '/projects/:id/releases/:version/reviews',
                      :controller => 'survey', :action => 'review',
                      :requirements => {:version => /.+/}
  map.project_review '/projects/:id/reviews', 
                      :controller => 'survey', :action => 'review'

  #####################
  #resources:
  #####################
  map.resources :openfoundry,
                :collection => { :search => :any ,
				 :foundry_sync => :any
				}
  map.resources :category
  map.resources :projects,
                :collection => { :list => :get, :applied => :get, 
			         :tableizer => :get, :test_action => :any },
                :member => { :sympa => :get, :viewvc => :get, :websvn => :get, 
			     :role_users => :any, 
                             :member_edit => :any, :member_delete => :post,
                             :member_add => :post, :permission_edit => :get,
                             :member_change => :post, :role_update => :any,
                             :group_update => :any,
                             :group_create => :any, :group_delete => :get,
                             :role_new => :any, :role_create => :any, :vcs_access => :any,
                             :test_action => :any}
  map.resources :news,
                :singular => 'news1',
                :collection => { :new_release => :any },
                :path_prefix => '/projects/:project_id'
  map.resources :news,
                :singular => 'news1',
                :name_prefix => 'site_'

  #####################
  #resources: jobs
  #####################
  map.resources :jobs,
                :path_prefix => '/projects/:project_id'
  map.connect '/jobs', :controller => :jobs, :action => :index
  map.resources :jobs,
                :collection => { :list => :get }
  #####################
  #resources: citations
  #####################
  map.resources :citations,
                :path_prefix => '/projects/:project_id'
  #####################
  #resources: references
  #####################
  map.resources :references,
                :path_prefix => '/projects/:project_id'
  #####################
  #resources: releases
  #####################
  map.resources :releases,
    :path_prefix => '/projects/:project_id',
    :collection => ['download'],
    :member => { :uploadfiles => :any, :delete => :post, 
                 :addfiles => :post, :removefile => :post,
                 :editfile => :post, :updatefile => :post,
                 :editrelease => :post, :updaterelease => :post,
                 :viewrelease => :post, :viewfile => :post,
                 :reload => :post,
                 :web_upload => :post, :delete_files => :post,
                 :download => :any, :new_releases => :any },
    :singular => :release
  map.resources :releases,
    :collection => ['latest', 'top']
  map.feed_release '/releases/new_release_feed.:format', 
                  :controller => :releases, :action => :new_release_feed
  map.feed_release '/releases/top_download_feed.:format', 
                  :controller => :releases, :action => :top_download_feed
  #####################
  #resources: other...
  #####################
  map.resources :kwiki,
                :singular => 'kwiki1',
                :path_prefix => '/projects/:project_id'
  map.resources :rt,
                :singular => 'rt1',
                :path_prefix => '/projects/:project_id'
  map.resources :rt,
                :singular => 'rt1',
                :name_prefix => 'site_'
  map.resources :survey,
                :path_prefix => '/projects/:project_id',
                :member => {:update => :post, :apply => :any, :delete => :post}

  map.resources :nscreports,
                :controller => 'nscreports',
                :path_prefix => '/projects/:project_id/nsc'
  map.resources :images,
                :only => [:cached_image, :upload, :email_image],
                :collection => {:cached_image => :get, :upload => :any,
                                :email_image => :get}

  map.resource :user,
    :only => [:logout, :login, :index],
    :controller => :user,
    :collection => {:dashboard => :get},
    :member => {:home => :get,:index => :get,  
                :login => :get, :logout => :get, 
                :search => :post}
  map.connect '/user', :controller => :user, :action => :index

  map.resource :rescue,
    :only => [:not_found],
    :controller => :rescue,
    :member => {:not_found => :get}

  map.resources :webhosting,
                :collection => { :how_to_upload => :get }
  
  map.resources :help,
                :collection => { :index => :any, :nsc_project => :any }

  #####################
  #rss feeds:
  #####################
  
  # feed for new projects
  map.new_projects_feed '/projects/news_projects_feed.:format',
                        :controller => 'projects', :action => 'new_projects_feed'
  # feed for new openfoundry news
  map.new_openfoundry_news_feed '/news/new_openfoundry_news_feed.:format',
                        :controller => 'news', :action => 'new_openfoundry_news_feed'
  # feed for new project news
  map.new_project_news_feed '/news/new_project_news_feed.:format',
                        :controller => 'news', :action => 'new_project_news_feed'
  #####################
  #misc:
  #####################
  map.download1 '/projects/:project_id/download',
    :controller => 'releases',
    :action => 'download'  
  # Install the default route as the lowest priority.
  #map.connect ':controller/:action/:id.:format'
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action.:format'


  #for ~user home, eg: /~tim goes to :controller => :user, :id => 'tim' 
  #map.connect '~:user_alias', :controller => 'user', :action => 'home'

  #for downloader survey 
  map.downloader 'download_path/:project_name/:release_version/:file_name/survey/:id',
    :controller => 'survey',
    :action => 'apply',
    :requirements => {:file_name => /.+/, :release_version => /.+/}

  #for download area~
  map.download 'download_path/:project_name/:release_version/:file_name',
    :controller => 'openfoundry',
    :action => 'download',
    :requirements => {:file_name => /.+/, :release_version => /.+/}
end
