#OpenFoundry lib
require 'yaml'

module OpenFoundry
  module Message
    # for deliver ACTIONS, like CRUD
    ACTIONS = {
      :create => 'create', 
      :update => 'update', 
      :delete => 'delete'}.freeze
    
    # for delivery TYPE, like object type
    TYPES = {
      :project => 'project', 
      :user => 'user' , 
      :relation => 'relation'}.freeze
    
    include ActiveMessaging::MessageSender
    
    publishes_to :ossf_msg
    
    def send_msg(type, action, data)
      publish(:ossf_msg, 
        "#{YAML::dump({'type' => type, 'action' => action, 'data' => data})}"
      )
    end
    
  end
end