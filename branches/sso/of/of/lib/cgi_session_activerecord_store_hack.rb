class CGI
  class Session
    class ActiveRecordStore
      class Session < ActiveRecord::Base
        #before_save :update_host_user_id
        #before_update :update_host_user_id
        def update_host_user_id
          #logger.info('&&&&&&&&&&&&&& HACKED &&&&&&&&&&&&&&&&7')
          host = request.remote_ip
          user_id = data[:user]? data['user'].id : nil
        end
        def marshal_data!
          return false if !loaded?
          write_attribute(:host,self.data[:host])
          write_attribute(:user_id,self.data['user'].id) if self.data['user']
          write_attribute(@@data_column_name, self.class.marshal(self.data))
        end
      end
    end
  end
end
