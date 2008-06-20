class Session < ActiveRecord::Base
  class << self
    def online_users
      Session.find_by_sql("select distinct(user_id) from sessions where user_id is not null and updated_at > '#{OPENFOUNDRY_SESSION_EXPIRES_AFTER.ago.strftime '%Y-%m-%d %H:%M:%S'}' order by updated_at desc limit 25").collect{|s| User.find_by_id(s.user_id)}.reject{|u| u.t_conceal_login}
    end

  end
end
