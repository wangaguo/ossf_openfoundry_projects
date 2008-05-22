ActionController::Routing::Routes.draw do |map|
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
  map.resources :projects,
                :collection => { :applied => :get, :tableizer => :get },
                :member => { :sympa => :get, :viewvc => :get, :role_users => :any, :roles_edit => :any, :role_update => :any, :role_new => :any, :role_create => :any  }
  map.resources :users, 
                :controller => :user                
  map.resources :news,
                :singular => 'news1',
                :path_prefix => '/projects/:project_id'
  map.resources :news,
                :singular => 'news1',
                :collection => {:project => :get},
                :name_prefix => 'site_'  
  #for project releases
  map.resources :releases,
    :path_prefix => '/projects/:project_id',
    :member => { :uploadfiles => :any, :delete => :post, 
                 :addfiles => :post, :removefile => :post },
    :singular => :release
  map.connect '/projects/:project_id/:controller', 
       :controller => 'kwiki',
       :action => 'index'
  map.resources :rt,
                :singular => 'rt1',
                :path_prefix => '/projects/:project_id'
  map.resources :rt,
                :singular => 'rt1',
                :name_prefix => 'site_'
  
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
  
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action/:id'
  
  map.download 'releases/top',
    :controller => 'releases',
    :action => 'top'
   # :requirements => {:file_name => /.+/, :release_name => /.+/}
  
  #for download area~
  map.download 'download_path/:project_name/:release_name/:file_name',
    :controller => 'openfoundry',
    :action => 'download',
    :requirements => {:file_name => /.+/, :release_name => /.+/}
#  require "pp"
#  pp map.instance_eval("@set").instance_eval("@named_routes").instance_eval("@helpers").map {|x| x.to_s}.grep(/url/).select {|x| not x=~/^(hash|formatted)/}

end
