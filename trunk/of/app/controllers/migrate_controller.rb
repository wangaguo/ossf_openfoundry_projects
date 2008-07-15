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
    News.destroy_all "catid >0"
#    of_data = Net::HTTP.get(URI.parse('http://rt.openfoundry.org/NoAuth/FoundryDumpForOF.html?Model=News&pid=744'))
    of_file = open("/tmp/FoundryDumpNews.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    News.record_timestamps = false
    of_data_json['news'].each do |item|
      news = News.new(item)
      news.save
    end
    render :text => 'done'
  end
  
  def jobs
    Jobs.destroy_all ""
    of_file = open("/tmp/FoundryDumpJob.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    News.record_timestamps = false
    of_data_json['jobs'].each do |item|
      job = Job.new(item)
      job.save
    end
    render :text => 'done'
  end
  
  def citations
    Citation.destroy_all ""
    of_file = open("/tmp/FoundryDumpCitation.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    News.record_timestamps = false
    of_data_json['Citation'].each do |item|
      citation = Citation.new(item)
      citation.save
    end
    render :text => 'done'
  end
end

