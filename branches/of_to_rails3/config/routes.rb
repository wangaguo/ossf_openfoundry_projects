OpenFoundry::Application.routes.draw do |map|

  base_url = Rails::Application.config.root_path
  map.root :controller => 'openfoundry', :path_prefix => base_url 
  #####################
  # API!!
  #####################
  map.resource :api,
    :controller => :api, :only => [:user,:project],
    :member => {:user => :get, :project => :get}, :path_prefix => base_url
  #####################
  #administration:
  #####################
  map.connect 'site_admin', :controller => 'site_admin/site_admin', :path_prefix => base_url

  map.namespace :site_admin, :path_prefix => base_url+'/site_admin'  do |admin|
    admin.resource :admin, :controller => 'site_admin',
		   :member => [:resend, :aaf_rebuild, :batch_add_users, :edit_code, :new_site_mail, :big_files]
    admin.resources :projects,
                    :member => {:change_status_form => :any,
                                :list => :any,
                                :projects_upload => :any,
				:change_status => :any
                                }
    admin.resources :users
    admin.resources :news
    admin.resources :tags
  end
  map.project_jobs '/projects/jobs', :controller => 'jobs', :action => 'project_jobs', :path_prefix => base_url
  map.project_news '/projects/news', :controller => 'news', :action => 'project_news', :path_prefix => base_url

  #####################
  #downloaders' reviews: for project, release, and file
  #####################
  map.file_review '/projects/:id/releases/:version/files/:path/reviews',
                      :controller => 'survey', :action => 'review',
                      :requirements => {:path => /.+/, :version => /.+/}, :path_prefix => base_url
  map.release_review '/projects/:id/releases/:version/reviews',
                      :controller => 'survey', :action => 'review',
                      :requirements => {:version => /.+/}, :path_prefix => base_url
  map.project_review '/projects/:id/reviews', 
                      :controller => 'survey', :action => 'review', :path_prefix => base_url

  #####################
  #resources:
  #####################
  map.resources :openfoundry,
                :collection => { :search => :any, :download => :get, :is_project_name => :any,
				 :foundry_dump => :any, :foundry_sync => :any,
				 :redirect_rt_openfoundry_org => :any,
				 :authentication_authorization => :any,
				 :authentication_authorization_II => :any,
				 :get_session_by_id => :any,
				 :get_session_by_id2 => :any,
				 :get_user_by_session_id => :any
				}, :path_prefix => base_url
  map.resources :category,
  		:collection => { :list => :get }, :path_prefix => base_url
  map.resources :projects,
                :collection => { :list => :get, :applied => :get, 
			         :tableizer => :get,
                                 :new_projects_feed => :get},
                :member => { :sympa => :get, :viewvc => :get, :websvn => :get, 
			     :role_users => :any, 
                             :member_edit => :any, :member_delete => :post,
                             :member_add => :post, :permission_edit => :get,
                             :member_change => :post, :role_update => :any,
                             :group_update => :any,
                             :group_create => :any, :group_delete => :any,
                             :role_new => :any, :role_create => :any, :vcs_access => :any
                             },
                :path_prefix => base_url

  map.resources :news,
                :singular => 'news1',
                :collection => { :new_release => :any },
                :path_prefix => base_url+'/projects/:project_id'
  map.resources :news,
                :singular => 'news1',
                :collection => {:new_openfoundry_news_feed => :get,:new_project_news_feed => :get},
                :name_prefix => 'site_', :path_prefix => base_url

  #####################
  #resources: jobs
  #####################
  map.resources :jobs,
                :path_prefix => base_url+'/projects/:project_id'
  scope base_url do
    get '/jobs', :controller => :jobs, :action => :index, :path_prefix => base_url, :as => :jobs_index
  end
  map.resources :jobs,
                :collection => { :list => :get }, :path_prefix => base_url
  #####################
  #resources: citations
  #####################
  map.resources :citations,
                :path_prefix => base_url+'/projects/:project_id'
  #####################
  #resources: references
  #####################
  map.resources :references,
                :path_prefix => base_url+'/projects/:project_id'
  #####################
  #resources: releases
  #####################
  map.resources :releases,
    :path_prefix => base_url+'/projects/:project_id',
    :collection => {:download => :any} ,
    :member => { :uploadfiles => :any, :delete => :post, 
                 :addfiles => :post, :removefile => :post,
                 :editfile => :any, :updatefile => :post,
                 :editrelease => :post, :updaterelease => :post,
                 :viewrelease => :post, :viewfile => :post,
                 :reload => :post,
                 :web_upload => :post, :delete_files => :post,
                 :download => :any, :new_releases => :any },
    :singular => :release
  map.resources :releases,
    :collection => {:latest => :any, :top => :any,:new_release_feed => :get, :top_download_feed => :get }, :path_prefix => base_url
  #####################
  #resources: other...
  #####################
  map.resources :kwiki,
                :singular => 'kwiki1',
                :path_prefix => base_url+'/projects/:project_id'
  map.resources :rt,
                :singular => 'rt1',
		:collection => { :report => :get },
                :path_prefix => base_url+'/projects/:project_id'
  map.resources :rt,
                :singular => 'rt1',
                :name_prefix => 'site_', :path_prefix => base_url
  map.resources :survey,
                :path_prefix => base_url+'/projects/:project_id',
                :member => {:update => :post, :apply => :any, :delete => :post}

  map.resources :nscreports,
                :controller => 'nscreports',
                :path_prefix => base_url+'/projects/:project_id/nsc'
  map.resources :images,
                :only => [:cached_image, :upload, :email_image],
                :collection => {:cached_image => :get, :upload => :any,
                                :email_image => :get}, :path_prefix => base_url

  map.resource :user,
    :only => [:logout, :login, :index],
    :controller => :user,
    :collection => {:dashboard => :get},
    :member => {:home => :get,:index => :get,  
                :login => :get, :logout => :get, 
                :search => :post}, :path_prefix => base_url
  map.connect '/user', :controller => :user, :action => :index, :path_prefix => base_url

  map.resource :rescue,
    :only => [:not_found],
    :controller => :rescue,
    :member => {:not_found => :get}, :path_prefix => base_url

  map.resources :webhosting,
                :collection => { :how_to_upload => :get }, :path_prefix => base_url
  
  map.resources :help,
                :collection => { :index => :any, :nsc_project => :any, :vcs => :any }, :path_prefix => base_url

  #####################
  #misc:
  #####################
  map.download1 '/projects/:project_id/download',
    :controller => 'releases',
    :action => 'download', :path_prefix => base_url
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format', :path_prefix => base_url
  map.connect ':controller/:action/:id', :path_prefix => base_url
  map.connect ':controller/:action.:format', :path_prefix => base_url


  #for ~user home, eg: /~tim goes to :controller => :user, :id => 'tim' 
  #map.connect '~:user_alias', :controller => 'user', :action => 'home'

  #for downloader survey 
  map.downloader 'download_path/:project_name/:release_version/:file_name/survey/:id',
    :controller => 'survey',
    :action => 'apply',
    :requirements => {:file_name => /.+/, :release_version => /.+/}, :path_prefix => base_url

  #for download area~
  map.download 'download_path/:project_name/:release_version/:file_name',
    :controller => 'openfoundry',
    :action => 'download',
    :requirements => {:file_name => /.+/, :release_version => /.+/}, :path_prefix => base_url
end
