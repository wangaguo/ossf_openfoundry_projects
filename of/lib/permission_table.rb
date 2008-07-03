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
      :role_new => :role_edit,
      :role_create => :role_edit,
      :role_edit => :role_edit,
      :role_update => :role_edit,
      :role_destory => :role_edit,
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
      :new => :news,
      :create => :news,
      #:_home_news,
      :destroy => :news,
      :edit => :news,
      :update => :news
      #:index,
      #:list,
      #:project,
      #:show
      #:permit_redirect
    },
    :jobs => jobs_pt = {
      :new => :job,
      :create => :job,
      :destroy => :job,
      :edit => :job,
      :update => :job
    },
    :releases => releases_pt = {
      :new => :release,
      :create => :release,
      :addfiles => :release,
      :uploadfiles => :release,
      :edit => :release,
      :update => :release,
      #:index
      #:latest
      #:list
      :removefile => :release,
      :delete => :release
      #:show
      #:top
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
