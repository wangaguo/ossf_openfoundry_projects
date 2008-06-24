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
      #:delete_role,
      #:role_create,
      #:role_destory,
      #:role_edit,
      #:role_new,
      #:role_update,
      #:role_users,
      #:roles_edit,
      #:set_project,
      #:set_project_id,
      #:set_role,
      #:sympa,
      #:the_rest,
      #:update,
      #:vcs_access,
      #:viewvc
    },
    :user => user_pt = {
    },
    :news => news_pt = {
    },
    :releases => releases_pt = {
    }#,
    #:rt,
    #:kwiki,
    #:images,
  }
  #set default permissions
  default_permission = :ALLOW_EVERYONE  

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
