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

    if ( env["PATH_INFO"] =~ /^\/of\/sync_data/ ) and ( env["REMOTE_ADDR"] =~ /140.109.*/ )

			if req = Rack::Request.new(env) and req.post? and req.params["data"]
				userdata = JSON.parse(req.params["data"])["user"]
				userdata.delete("id")

				case req.params["action"]
				when "create"
					if User.find(:first, :conditions => {:login => userdata['name']})
						[200, {"Content-Type" => "text/html"}, ["true"]]
					else
						syncuser = User.new(:login => userdata['name'])
						usertags = userdata.select{ |k, v| k=~ /^t_/ } || {}
					
						userdata.each { |k, v| syncuser.send(k + "=", v) if syncuser.respond_to? "#{k}=" }
						(usertags.each { |k, v| syncuser.send(k + "=", v) } if syncuser.save)? 
							[200, {"Content-Type" => "text/html"}, ["true"]] :
							[200, {"Content-Type" => "text/html"}, ["false"]]
					end
				when "update"
					if syncuser	= User.find(:first, :conditions => {:login => userdata['name']})
						userdata.delete('name')

						(userdata.each { |k, v| syncuser.send(k + "=", v) if syncuser.respond_to? "#{k}=" }; syncuser.save if not userdata.empty?)?
							[200, {"Content-Type" => "text/html"}, ["true"]] :
							[200, {"Content-Type" => "text/html"}, ["false #{syncuser.errors}"]]
					else
						[200, {"Content-Type" => "text/html"}, ["false, not found: #{userdata["name"]}"]]
					end
				else
					[200, {"Content-Type" => "text/html"}, ["false, action error"]]
				end

			else
				[200, {"Content-Type" => "text/html"}, ["false"]]
    	end

		else
			[404, {"Content-Type" => "text/html"}, ["false"]]
  	end

	end
end
