class PermissionCache < ActiveRecord::Base
  belongs_to :user
  belongs_to :permission
  belongs_to :project
end
