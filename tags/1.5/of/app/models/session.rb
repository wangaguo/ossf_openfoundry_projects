require 'memcache'
class Session < ActiveRecord::Base
  class << self
    def user_login(user_id)
      #access_memcache_with_lock do 
      #  online = ::Rails.cache.read('session-pool') || {}
      #  online[user_id] = Time.now
      #  ::Rails.cache.write('session-pool', online)
      #end
    end

    def user_logout(user_id)
      #access_memcache_with_lock do 
      #  online = ::Rails.cache.read('session-pool') || {}
      #  online.delete(user_id)
	    #  ::Rails.cache.write('session-pool', online)
      #end
    end

    def online_users(options = {})
     #limit = options[:limit] || 20
     #online = ::Rails.cache.read('session-pool')||{}
     #user_ids = online.keys.compact
     #user_ids.sort!{|u1,u2| online[u1] <=> online[u2] }
     #rtn = []
     #while(rtn.length < limit)
     #  u = User.valid_users.find_by_id(user_ids.pop)	     
     #  break unless u 
     #  rtn << u unless( u.t_conceal_login or rtn.member? u )                    
     #  break if user_ids.empty?
     #end
     #rtn
    end

    private 

    def access_memcache_with_lock
      t=1000
      while(t > 0)
        t-=1
        next if ::Rails.cache.exist?('session-pool:lock')
        ::Rails.cache.write('session-pool:lock','!')
	      yield
        ::Rails.cache.delete('session-pool:lock')
        break
      end
    end
  end
end
