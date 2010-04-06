# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
#
#	post url
# => http://ssodev.openfoundry.org/of/sync_data/ 
#
# post data
# => action: add or alter
# => data	 : json data (login field is necessary) 
#
class SyncData

  def self.call(env)

    if env["PATH_INFO"] =~ /^\/sync_data/

			if req = Rack::Request.new(env) and req.post? and req.params["data"]
				userdata = JSON.parse(req.params["data"])

				case req.params["action"]
				when "add"
					syncuser = User.new
					usertags = userdata.select{ |k, v| k=~ /^t_/ }
					
					userdata.each { |k, v| syncuser.send(k + "=", v) }
					(usertags.each { |k, v| syncuser.send(k + "=", v) } if syncuser.save)? 
						[200, {"Content-Type" => "text/html"}, ["ADD_OK"]] :
						[200, {"Content-Type" => "text/html"}, ["ADD_ERROR"]]
				when "alter"
					if syncuser	= User.find(:first, :conditions => {:login => userdata["login"]})
						userdata.delete("login")

						(userdata.each { |k, v| syncuser.send(k + "=", v) }; syncuser.save if not userdata.empty?)?
							[200, {"Content-Type" => "text/html"}, ["ALTER_OK"]] :
							[200, {"Content-Type" => "text/html"}, ["ALTER_ERROR"]]
					end
				else
					[200, {"Content-Type" => "text/html"}, ["NO_ACTION"]]
				end

			else
				[200, {"Content-Type" => "text/html"}, ["NO_DATA"]]
    	end

		else
			[404, {"Content-Type" => "text/html"}, ["Not Found"]]
  	end

	end
end
