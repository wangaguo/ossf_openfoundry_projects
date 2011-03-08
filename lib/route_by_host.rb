# REF: actionpack-2.1.0/lib/action_controller/routing/recognition_optimisation.rb
# 
#
# 
# for migrating from rt.openfoundry.org
#
ActionController::Routing::RouteSet.class_eval "def extract_request_environment(request)
  { :method => request.method, :host => request.host }
end"

module ActionController
  module Routing
    class RouteSet
      alias_method :recognize_path_without_host, :recognize_path
      def recognize_path(path, environment={})
        if environment[:host] == 'rt.openfoundry.org'
          warn "rt.openfoundry.org!!!!!"
          { :controller => 'openfoundry', :action => 'redirect_rt_openfoundry_org' }
        else
          recognize_path_without_host(path, environment)
        end
      end
    end
  end
end
