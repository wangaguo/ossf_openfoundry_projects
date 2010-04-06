class MsgHandleProcessor < ApplicationProcessor

  subscribes_to :queue_data

  def on_message(message)
		logger.debug "============================================================"
    logger.debug "[AMQ DATA RECEIVED] at [#{Time.now}]"
		logger.debug message 
		logger.debug "============================================================"
#		require 'pp'
#		pp YAML::load(message)
		
		rawdata = YAML::load(message)
		logger.debug "============================================================"
		case rawdata["action"]
			when "create"
				create_and_announce(rawdata["resource"], rawdata["description"]) if rawdata["description"]
			when "update"
				update_and_announce(rawdata["resource"], rawdata["description"]) if rawdata["description"]
			when "delete"
				delete_and_announce(rawdata["resource"], rawdata["description"]) if rawdata["description"]
			else
				logger.debug "[NO ACTION FOR RESOURCE] at [#{Time.now}]"
		end
		logger.debug "============================================================"

  end

	def create_and_announce(desmodel, desdata)
		newuser = desmodel.capitalize.constantize.new
		desdata.each { |k, v| newuser.send(k.to_s + "=", v) }
		logger.debug "[RESOURCE #{desmodel.upcase} INSERTED] at [#{Time.now}]" if newuser.save
	end

	def update_and_announce(desmodel, desdata)
		# set for resource conditions
		sqlcondition = {}
		case desmodel
			when "user"
				sqlcondition = { :login => desdata[:login] } 
				desdata.delete :login
			when "project"
				sqlcondition = { :name => desdata[:name] }
				desdata.delete :name
		end

		# find out the data and alter it!!
		if !sqlcondition.empty? and !desdata.empty?
			alterdata = desmodel.capitalize.constantize.find(:first, :conditions => sqlcondition)
			desdata.each { |k, v| alterdata.send(k.to_s + "=", v) }	
			logger.debug "[RESOURCE #{desmodel.upcase} ALTERED] at [#{Time.now}]" if alterdata.save
		end
	end

	def delete_and_announce(desmodel, desdata)
		# set for resource conditions
		sqlcondition = {}
		alterfield = {}
		case desmodel
			when "user"
				sqlcondition = { :login => desdata[:login] } 
				alterfield = { "status" => 3 }
			when "project"
				sqlcondition = { :name => desdata[:name] }
				alterfield = { "status" => 4 }
		end

		# find out the data and alter it's status!!
		if !sqlcondition.empty?
			alterdata = desmodel.capitalize.constantize.find(:first, :conditions => sqlcondition)
			alterfield.each { |k, v| alterdata.send(k + "=", v) }
			logger.debug "[RESOURCE #{desmodel.upcase} DELETED] at [#{Time.now}]" if alterdata.save
		end
	end

end
