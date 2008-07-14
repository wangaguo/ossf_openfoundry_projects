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
    
    #Project.send(:alias_method, :orig_valid?, :valid?)
    tmp = ""
    projects = j["projects"]
    projects.each do |p|
      #tmp += "#{p["id"]}  #{p["name"]} #{p["summary"]}" + "<br/>"
      p2 = Project.new(p)
      p2.id = p["id"]
      def p2.valid?; true; end
      p2.save!
      tmp += p2.pretty_inspect
    end
    #Project.send(:alias_method, :valid?, :orig_valid?)

    render :text => tmp, :layout => false
  end

  def news
    of_data = Net::HTTP.get(URI.parse('http://rt.openfoundry.org/NoAuth/FoundryDumpForOF.html'))
    of_data_json = JSON.parse(of_data)

    of_data_json['news'].each do |item|
      news = News.new(item)
      news.save
    end
    render :text => 'done'
  end
end

