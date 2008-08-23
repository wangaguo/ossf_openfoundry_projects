class Session < ActiveRecord::Base
  class << self
    def online_users(options = {})
     limit = options[:limit] || 20
     count = 0
     rtn = []
     while(rtn.length < limit)
       u = User.find_by_sql("select U.* from sessions S left join users U on S.user_id = U.id 
           where S.user_id is not null and
           S.updated_at > '#{OPENFOUNDRY_SESSION_EXPIRES_AFTER.ago.strftime '%Y-%m-%d %H:%M:%S'}'
                  order by S.updated_at desc 
                            limit 1 offset #{count}").first
       break unless u                     
       rtn << u unless u.t_conceal_login                     
       count=count+1
     end
     rtn
    end

  end
end
