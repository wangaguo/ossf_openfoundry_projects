module OpenFoundry
  module PermissionTable
  # for permission check
  PERMISSION_TABLE = {
    :openfoundry => openfoundry_pt = {
      #:authentication_authorization,
      #:download,
      #:foundry_dump,
      #:get_user_by_session_id,
      #:index,
      #:is_project_name,
      #:load_data,
      #:search,
      #:tag
    },
    :projects => projects_pt = {
      #:new,
      #:create,
      #:show,
      #:index,
      #:list,
      #:destory,
      :role_new => :role_new,
      :role_create => :role_new,
      :role_edit => :role_edit,
      :role_update => :role_edit,
      :role_destory => :role_delete,
      #:set_project,
      #:set_project_id,
      :roles_edit => :project_member,
      :role_users => :project_member,
      :set_role => :project_member,
      :delete_role => :project_member,
      #:sympa,
      #:the_rest,
      :update => :project_info,
      :edit => :project_info
      #:vcs_access,
      #:viewvc
    },
    :user => user_pt = {
    },
    :news => news_pt = {
      :new => :news_post,
      :create => :news_post,
      #:_home_news,
      :destroy => :news_delete,
      :edit => :news_edit,
      :update => :news_edit
      #:index,
      #:list,
      #:project,
      #:show
      #:permit_redirect
    },
    :releases => releases_pt = {
    }#,
    #:rt,
    #:kwiki,
    #:images,
  }
  #set default permissions
  default_permission = :allow_all  

  openfoundry_pt.default = default_permission
  projects_pt.default = default_permission
  user_pt.default = default_permission
  news_pt.default = default_permission
  releases_pt.default = default_permission

  default_pt = {}
  default_pt.default = default_permission
  PERMISSION_TABLE.default = default_pt
  
  PERMISSION_TABLE.freeze
  end
end
