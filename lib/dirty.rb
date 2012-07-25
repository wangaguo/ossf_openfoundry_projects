module OpenFoundry
  module VeryDirty
    def _(key)
      key
    end  
    def N_(key)
      key
    end  
  end
end
ActiveRecord::Base.send(:include, OpenFoundry::VeryDirty)
ActiveRecord::Base.send(:extend, OpenFoundry::VeryDirty)
