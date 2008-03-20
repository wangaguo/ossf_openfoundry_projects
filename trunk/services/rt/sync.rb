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
  #puts "============================="
  #puts m.inspect
  #puts "============================="

  type = m['type']
  action = m['action']
  data = m['data']

  case [type, action]
  when ['project', 'create']
    RTQueue.create_queue(data['id'], data['name'], data['summary'])
  when ['project', 'update']
    RTQueue.update_queue(data['id'], data['summary'])
  when ['user', 'create']
    RTUser.create_user(data['id'], data['name'])
  when ['user', 'update']
    RTUser.update_user(data['id'], data['name'], data['email'])
  when ['roles_users', 'create']
    RTUser.create_relation(data['user']['id'], data['project']['id'], data['role']['name'])
  when ['roles_users', 'delete']
    RTUser.delete_relation(data['user']['id'], data['project']['id'], data['role']['name'])
  else
    raise "bad input!!"
  end

end

###############################################


require "config.rb" # TODO: path

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
    process(msg.body)
    conn.ack msg.headers["message-id"]
  end
eusure
  conn.disconnect # useless!
  puts "bye"
end




