class SiteAdmin::UserController < SiteAdmin
  active_scaffold :User do |config| 
    config.list.columns = [:login, :verified, :status, :created_at, :updated_at]
    config.columns = [:login, :verified, :status, :created_at, :updated_at]
  end
end
