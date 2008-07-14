require 'net/http'
require 'json'
require 'pp'
class MigrateController < ApplicationController
  def projects

    url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJsonForMigrationToOF.html?secret=df893jfdughjud'
    #url = 'http://rt.openfoundry.org/NoAuth/FoundryCitationsDump.html'
    
    a = Net::HTTP.get(URI.parse(url))
    #puts a
    #
    j = JSON.parse(a)
    ##require "pp"
    #pp j
    #render :text => j.pretty_inspect, :layout => false
    
    tmp = ""
    projects = j["projects"]
    projects.each do |p|
      tmp += "#{p["id"]}  #{p["name"]} #{p["summary"]}" + "<br/>"
    end
    render :text => tmp, :layout => false
  end

end

