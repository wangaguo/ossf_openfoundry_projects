# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
require 'action_pack'
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

    if ( env["PATH_INFO"] =~ /^\/of\/sync_data/ ) and ( env["REMOTE_ADDR"] =~ /140.109.*|192.168.*/ )

			if req = Rack::Request.new(env) and req.post? and req.params["data"]
				userdata = JSON.parse(req.params["data"])["user"]
				userdata.delete("id")

				case req.params["action"]
				when "create"
					if User.valid_users.find(:first, :conditions => {:login => userdata['name']})
						[200, {"Content-Type" => "text/html"}, ["true"]]
					else
						syncuser = User.new(:login => userdata['name'], :verified => 1)
						usertags = userdata.select{ |k, v| k=~ /^t_/ } || {}
					
						userdata.each { |k, v| syncuser.send(k + "=", v) if syncuser.respond_to? "#{k}=" }
						if syncuser.save
							#ActionController::send_msg(
							#	ActionController::TYPES[:user],
							#	ActionController::ACTIONS[:create],
							#	{'id' => syncuser.id, 'name' => syncuser.login, 'email' => syncuser.email})
							usertags.each { |k, v| syncuser.send(k + "=", v) }
							[200, {"Content-Type" => "text/html"}, ["true"]] 
						else
							[200, {"Content-Type" => "text/html"}, ["false"]]
						end
					end
				when "update"
					if syncuser	= User.valid_users.find(:first, :conditions => {:login => userdata['name']})
						userdata.delete('name')
						userdata.each { |k, v| syncuser.send(k + "=", v) if syncuser.respond_to? "#{k}=" } 
						if syncuser.save 
							#ActionController::send_msg(
							#	ActionController::TYPES[:user],
							#	ActionController::ACTIONS[:update],
							#	{'id' => syncuser.id, 'name' => syncuser.login, 'email' => syncuser.email})
							[200, {"Content-Type" => "text/html"}, ["true"]]
						else
							[200, {"Content-Type" => "text/html"}, ["false #{syncuser.errors}"]]
						end
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
