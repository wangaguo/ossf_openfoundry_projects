# To see what changes, do this:
# $ cd /home/openfoundry/of
# $ vimdiff sorted_old_routes sorted_new_routes
# and PLEASE DON'T MODIFY THESE TWO FILE!!!

OpenFoundry::Application.routes.draw do |map|

  base_url = OpenFoundry::Application.config.root_path

  scope base_url do
    root :to => 'openfoundry#index'

    #####################
    # Metal:
    #####################
    match '/projacts' => 'projacts#index'
    match '/sync_data', :to => SyncData, :as => :sync_data

    # remember add `curl http://host/of/counter_log_flusher` to cron please
    match '/counter_log_flusher' => CounterLogFlusher.action(:index)

    #####################
    # RSS:
    #####################
    get '/rss' => 'rss#index'

    #####################
    # API!!
    #####################
    namespace :api do
      get :project
      get :user
    end

    #####################
    #administration:
    #####################
    namespace :site_admin do
      root :to => 'site_admin#index'
      namespace :site_admin, :path => :admin, :as => :admin do
        get '/' => :index
        get :resend
        get :aaf_rebuild
        get :batch_add_users
        get :edit_code
        match :new_site_mail
        get :big_files
        get :manage_tags
        get :tag_status
        get :nsc_download
        post :nsc_download
        post :switch_user_search
        get '/switch_user/:id' => :switch_user, :as => :switch_user
        get :member_edit
        post :member_change
        post :member_delete
        get '/counter_logs/search' => :search_counter_logs_index, :as => :search_counter_logs_index
        post '/counter_logs(.:format)' => :search_counter_logs, :as => :search_counter_logs
      end

      resources :projects do
        member do
          # FIXME: There is no 'any' method in rails 3 i think, so these settings may cause not found error. (aya
          # I'll mark ANY at future routes, if it's method is not GET, just feel free to modify it
          get :change_status_form # ANY
          get :list               # ANY
          get :projects_upload    # ANY
          post :change_status      # ANY
        end
        match :csv, :on => :collection
      end
      resources :user 
      resources :news
      resources :tags do
        collection do
          match :fetch
          match :edit
          match :delete
          match :ready
          match :pending
        end
      end
    end

    #####################
    # projects:
    #####################
    get '/projects/jobs' => 'jobs#project_jobs', :as => :home_project_jobs
    get '/projects/news' => 'news#project_news', :as => :home_project_news

    resources :projects do
      collection do
        get :list
        get :applied
        get :tableizer
        match :icon_album
#        get :new_projects_feed
        get :find_by_id_or_name
      end

      member do
        # FIXME: 'any' will use get by my default. (aya
        get :sympa
        get :viewvc
        get :websvn
        get :role_users      # ANY, UGLY... Need a role controller in future. (aya
        get :member_edit     # ANY
        post :member_delete  # UGLY... Need a member controller in future. (aya
        post :member_add
        get :permission_edit
        post :member_change
        get :role_update     # ANY
        post :group_update    # ANY, UGLY... Need a group controller in future. (aya
        post :group_create    # ANY
        post :group_delete    # ANY
        get :role_new        # ANY
        get :role_create     # ANY
        get :vcs_access      # ANY
        get :new_release, :path => '/news/new_release', :controller => 'news'
      end

      # in resource projects

      resources :releases do
        collection do
          get :download          # ANY
        end

        member do
          get :uploadfiles    # ANY, UGLY... Need a file controller in future. (aya
          post :delete
          post :addfiles
          post :removefile
          get :editfile       # ANY
          post :updatefile
          post :editrelease
          post :updaterelease
          post :viewrelease
          post :viewfile
          post :reload
          post :web_upload
          post :delete_files
          get :download       # ANY
          get :new_releases   # ANY
          get :files
        end
      end

      # in resource projects

      resources :news
      resources :jobs
      resources :citations
      resources :references
      resources :kwiki
      resources :rt do
        collection do
          get :report
        end
      end
      resources :survey do
        member do
          post :update
          get :apply # ANY
          post :delete
        end
      end
      resources :nscreports, :path => '/nsc/nscreports'
      resources :wiki, :constraints => { :id => /[^\/]+/ } do
        member do
          get 'add'
          get 'page'
          get 'edit'
          post 'edit'
          get 'revisions'
          get 'diff'
          match 'revisions/:rid' => 'wiki#revision_page'
          post 'preview'
        end
        collection do
          get 'index'
          get 'list'
          post 'list'
          get 'help'
          post 'web_upload'
          get 'files'
          post 'delete_files'
        end
      end

      get '/download' => 'releases#download'
    end

    resources :releases, :only => [] do
      collection do
        get :latest            # ANY
        get :top               # ANY
      end
    end

    resources :category do
      collection do
        match :list
      end
    end

    get '/openfoundry' => 'openfoundry#index'

    namespace :openfoundry do
      get :search                          # ANY
      get :download
      get :is_project_name                 # ANY
      get :foundry_dump                    # ANY
      get :foundry_sync                    # ANY
      get :redirect_rt_openfoundry_org     # ANY
      get :authentication_authorization    # ANY
      get :authentication_authorization_II # ANY
      get :get_session_by_id               # ANY
      get :get_session_by_id2              # ANY
      get :get_user_by_session_id          # ANY
    end

    resources :news

    get '/jobs' => 'jobs#index'

    resources :jobs do
      collection do
        get :list
      end
    end

    resources :images, :only => [] do
      collection do
        get '/cached_image/:id', :action => :cached_image, :as => :cached_image
        get '/email_image/:id', :action => :email_image, :as => :email_image
        post :upload # ANY
      end
    end

    resource :user, :only => [], :controller => 'user' do
      get :dashboard
      get :home
      get :index
      get :login
      get :logout
      post :search
      get :ajax_update_project_list
      get :welcome
    end

    get '/user' => 'user#index'

    namespace :rescue do
      get :not_found
    end

    namespace :webhosting do
      get '/', :action => :index
      get :how_to_upload
    end

    namespace :help do
      get '/', :action => 'index' # ANY
      get :nsc_project # ANY
      get :vcs # ANY
    end

    namespace :nsc do
      get :report_status
      get :download_count
      get :nscid2name
    end

    # NOTE: why not just put in projects/releases as a resource?
    match '/download_path/:project_name/:release_version/:file_name/survey/:id' => 'survey#apply',
      :as => :downloader,
      :constraints => { :file_name => /.+/, :release_version => /.+/ },
      :via => [:get, :post]
    get '/download_path/:project_name/:release_version/:file_name' => 'openfoundry#download', 
      :as => :download,
      :constraints => { :file_name => /.+/, :release_version => /.+/ }
    get '/projects/:id/releases/:version/files/:path/reviews' => 'survey#review', :as => :file_review,
      :constraints => { :version => /.+/, :path => /.+/ }
    get '/projects/:id/releases/:version/reviews' => 'survey#review', :as => :release_review,
      :constraints => { :version => /.+/ }
    get '/projects/:id/reviews' => 'survey#review', :as => :project_review
    # NOTE: Legacy route (remove it if possible)
    #match '/:controller(/:action(/:id))'
  end
  match '*path' => 'rescue#rescue_routing_error' 
end
