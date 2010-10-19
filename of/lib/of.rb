#OpenFoundry lib
require 'yaml'

module OpenFoundry
  module VeryDirty
    def _(key)
      key
    end  
    def N_(key)
      key
    end  
  end
  module Message
    def self.included(base)
      base.extend(ClassMethods)
    end

    # for deliver ACTIONS, like CRUD
    ACTIONS = {
      :create => :create, 
      :update => :update, 
      :delete => :delete}.freeze
    
    # for delivery TYPE, like object type
    TYPES = {
      :project => :project, 
      :user => :user , 
      :function => :function}.freeze
      include ActiveMessaging::MessageSender
      def send_msg(type, action, data)
        publish(:ossf_msg, 
          "#{YAML::dump({:type => type, :action => action, :data => data})}"
        )
      end

    module ClassMethods
      include ActiveMessaging::MessageSender
      
      publishes_to :ossf_msg
     
      def send_msg(type, action, data)
        publish(:ossf_msg, 
          "#{YAML::dump({:type => type, :action => action, :data => data})}"
        )
      end
    end
  end
end

ActiveRecord::Base.send(:include, OpenFoundry::Message)
ActiveRecord::Base.send(:include, OpenFoundry::VeryDirty)
ActiveRecord::Base.send(:extend, OpenFoundry::VeryDirty)


# (a, b) = normalize_values(%w[Ruby Perl JavaScript], %w[c Javascript perl]) {|x| x.downcase }
# pp a
# pp b
# (a, b) = normalize_values(%w[-2 0 1 -1], %w[-1 0 1 BSD])
# pp a
# pp b
#
# ["Perl", "JavaScript"]
# ["c"]
# ["0", "1", "-1"]
# ["BSD"]
#
def normalize_values(predefined_values, values, &cast_for_cmp)
  cast_for_cmp ||= lambda {|x| x }
  casted_pvs = predefined_values.map(&cast_for_cmp)
  indexes = []
  others = []
  values.each do |v|
    if idx = casted_pvs.index(cast_for_cmp.call(v))
      indexes[idx] = idx
    else
      others |= [v]
    end
  end
  [ predefined_values.values_at(* indexes.compact), others]
end
# >>  split_strip_compact(",,,,3 ,4, 5,")
# => ["3", "4", "5"]
def split_strip_compact(values_str, delimiter = ",")
  return [] if not values_str
  values_str.split(delimiter).map(&:strip).reject(&:blank?)
end
# >> split_strip_compact_array([",,,,3 ,4, 5,", "aa   , bb"])
# => ["3", "4", "5", "aa", "bb"]
def split_strip_compact_array(values_str_array, delimiter = ",")
  return [] if not values_str_array
  values_str_array.inject([]) {|s,x| s + split_strip_compact(x, delimiter)}
end

def left_slice(data, max_length)
  data_chars = data.mb_chars
  l = 0
  i = 0
  while l < max_length && data_chars[i] != nil #i <= title_chars.length-1
    l += data_chars[i] > 255.chr ? 2 : 1
    if l <= max_length
      i = i + 1
    end
  end
  data_chars[0 .. i - 1]
end

def right_slice(data, max_length)
  data_chars = data.chars
  l = 0
  i = -1
  while l < max_length && data_chars[i] != nil
    l += data_chars[i] > 255 ? 2 : 1
    if l <= max_length
      i = i - 1
    end
  end
  data_chars[i+1 .. -1]
end
