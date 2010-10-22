class Component < ActiveRecord::Base
  has_many :component_configs
  acts_as_list
end
