#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
ActiveMessaging::Gateway.define do |s|
  #s.destination :orders, '/queue/Orders'
  #s.filter :some_filter, :only=>:orders
  #s.processor_group :group1, :order_processor
  
  #s.destination :message_client, '/queue/MessageClient'
  
  s.destination :ossf_msg, '/topic/OSSF.MSG'
end