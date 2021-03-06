require "rubygems"
require "stomp"
require "yaml"

require "rt_model"


module Stomp # for 'client-id' header on CONNECT
  class Connection
    class << self
      attr_accessor :client_id
    end

    alias_method :_orig_transmit, :_transmit
    
    def _transmit(s, command, headers={}, body='')
      puts "debug: #{command} #{headers.inspect}"
      _orig_transmit(s, command, command == 'CONNECT' ? headers.merge('client-id' => Connection.client_id) : headers, body)
    end
  end
end

module ActiveRecord
  class Base
    def remove_attributes_protected_from_mass_assignment(attributes)
      attributes
    end
  end
end


# msg is a YAML string
def process(msg)
  #puts "============================="
  #puts msg
  m = YAML::load(msg)
  puts "process: #{Time.now} ============================="
  puts m.inspect
  puts "============================="

  type = m[:type].to_sym
  action = m[:action].to_sym
  data = m[:data]

  case [type, action]
  when [:project, :create]
    RTQueue.create_queue(data[:id], data[:name], data[:summary])
  when [:project, :update]
    RTQueue.update_queue(data[:id], data[:summary])
  when [:user, :create]
    RTUser.create_user_and_add_into_openfoundry_group(data[:id], data[:name], data[:email])
  when [:user, :update]
    RTUser.update_user(data[:id], data[:name], data[:email])
  when [:function, :create]
    RTUser.create_permission(data[:user_id], data[:project_id], data[:function_name])
  when [:function, :delete]
    RTUser.delete_permission(data[:user_id], data[:project_id], data[:function_name])
  else
    raise "bad input!!"
  end

end

###############################################


require "/usr/local/rt36/config.rb" # TODO: path

ActiveRecord::Base.establish_connection(
  :adapter => DB_TYPE,
  :database => DB_NAME,
  :username => DB_USER,
  :password => DB_PASSWORD,
  :host => DB_HOST,
  :encoding => 'UTF8'
)
ActiveRecord::Base.logger = Logger.new(STDOUT)



begin
  Stomp::Connection.client_id = MQ_CLIENT_ID
  conn = Stomp::Connection.open MQ_LOGIN, MQ_PASSCODE, MQ_HOST, MQ_PORT, true
  conn.subscribe MQ_THE_TOPIC, { :ack =>"client", "activemq.subscriptionName" => MQ_SUBSCRIPTION_NAME}
  while true
    msg = conn.receive # blocking
    unless ActiveRecord::Base.connection.active?
        ActiveRecord::Base.connection.reconnect!
        puts "Database Reconnected!"
        unless ActiveRecord::Base.connection.active?
          puts "FAILED - Database not available"
          break
        end
    end

    begin
      ActiveRecord::Base.transaction do
        process(msg.body)
      end
    rescue Object => e
      puts "error============================="
      puts msg.body.inspect
      puts "error============================="
      puts e.inspect
      puts "error============================="
    ensure
      conn.ack msg.headers["message-id"]
    end
  end
ensure
  conn.disconnect # useless!
  puts "bye"
end




