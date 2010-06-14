ActionController::Routing::Routes.draw do |map|

  #######################################################
  # For host specific routing, see lib/route_by_host.rb #
  #######################################################


  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.

  map.connect '', :controller => 'openfoundry'
  map.connect 'site_admin', :controller => 'site_admin/site_admin'
  map.project_jobs '/projects/jobs', :controller => 'jobs', :action => 'project_jobs'
  map.project_news '/projects/news', :controller => 'news', :action => 'project_news'

  #downloaders' reviews: for project, release, and file
  map.project_review '/projects/:id/reviews', 
                      :controller => 'survey', :action => 'review'
  map.release_review '/projects/:id/releases/:version/reviews',
                      :controller => 'survey', :action => 'review',
                      :requirements => {:version => /.+/}
  map.file_review '/projects/:id/releases/:version/files/:path/reviews',
                      :controller => 'survey', :action => 'review',
                      :requirements => {:path => /.+/, :version => /.+/}

  # feed for new projects
  map.new_projects_feed '/projects/news_projects_feed.:format',
                        :controller => 'projects', :action => 'new_projects_feed'

  map.resources :projects,
                :collection => { :applied => :get, :tableizer => :get, :test_action => :any },
                :member => { :sympa => :get, :viewvc => :get, :role_users => :any, 
                             :member_edit => :get, :member_delete => :post,
                              :member_add => :post,
                             :role_update => :any,
                             :role_new => :any, :role_create => :any, :vcs_access => :any,
                             :test_action => :any }
  #map.resources :users, 
  #              :controller => :user                

  # feed for new openfoundry news
  map.new_project_news_feed '/news/new_openfoundry_news_feed.:format',
                        :controller => 'news', :action => 'new_openfoundry_news_feed'
  # feed for new project news
  map.new_project_news_feed '/news/new_project_news_feed.:format',
                        :controller => 'news', :action => 'new_project_news_feed'
  map.resources :news,
                :singular => 'news1',
                :collection => { :new_release => :any },
                :path_prefix => '/projects/:project_id'
  map.resources :news,
                :singular => 'news1',
                :name_prefix => 'site_'
  map.resources :jobs,
                :path_prefix => '/projects/:project_id'
  map.resources :citations,
                :path_prefix => '/projects/:project_id'
  map.resources :references,
                :path_prefix => '/projects/:project_id'
  #for project releases
  map.resources :releases,
    :path_prefix => '/projects/:project_id',
    :collection => 'download',
    :member => { :uploadfiles => :any, :delete => :post, 
                 :addfiles => :post, :removefile => :post,
                 :editfile => :post, :updatefile => :post,
                 :editrelease => :post, :updaterelease => :post,
                 :viewrelease => :post, :viewfile => :post,
                 :reload => :post,
                 :download => :any },
    :singular => :release
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
  
  #  map.release 'project/:project_id/release', 
  #    :controller => 'release', :action => 'list'
  #  map.release 'project/:project_id/release/:release_id',
  #    :controller => 'release', :action => 'show'
  #  map.release 'project/:project_id/release/:action', 
  #    :controller => 'release'
  #  map.release 'project/:project_id/release/:action/:release_id', 
  #    :controller => 'release'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  map.download1 '/projects/:project_id/download',
    :controller => 'releases',
    :action => 'download'  
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action.:format'


  #for ~user home, eg: /~tim goes to :controller => :user, :id => 'tim' 
  map.connect '~:user_alias', :controller => 'user', :action => 'home'

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
  #  require "pp"
#  pp map.instance_eval("@set").instance_eval("@named_routes").instance_eval("@helpers").map {|x| x.to_s}.grep(/url/).select {|x| not x=~/^(hash|formatted)/}
#看controller的named_routes
#ActionController::Routing::Routes.named_routes.routes.each {|name, route| puts "%20s: %s" % [name, route] if name.to_s.include? "news"}; nil
end