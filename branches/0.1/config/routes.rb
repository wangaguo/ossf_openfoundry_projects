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
  map.connect 'projects', :controller => 'project', :action => 'list'
  map.resources :projects, 
                :controller => :project
  map.resources :users, 
                :controller => :user
  map.connect '/projects/:project_id/news', :controller => 'news', :action => 'list'                  
  map.resources :news,
                :path_prefix => '/projects/:project_id',
                :collection => { :create => :post },
                :member => { :update => :post, :destroy => :post },
                :singular => 'news1'
  
  #map.connect 'admin/:controller/:action/:id', :controller => 'admin/*'
  
  #for project releases
  map.resources :releases,
    :path_prefix => '/projects/:project_id',
    :member => { :uploadfiles => :any, :delete => :post, :addfiles => :post },
    :singular => :release
  
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
  
  require "pp"
  pp map.instance_eval("@set").instance_eval("@named_routes").instance_eval("@helpers").map {|x| x.to_s}.grep(/url/).select {|x| not x=~/^(hash|formatted)/}
  
end
