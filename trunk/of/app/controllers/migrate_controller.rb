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
#    select catid, count(*) from news where catid > 0 group by catid;
#    of_data = Net::HTTP.get(URI.parse('http://rt.openfoundry.org/NoAuth/FoundryDumpForOF.html?Model=News&pid=744'))
    of_file = open("/tmp/FoundryDumpNews.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    News.record_timestamps = false
    i = 0
    news = {}
    of_data_json['news'].each do |item|
      #news[item['catid']] = (news[item['catid']] || 0) +  1
      news = News.new(item)
      news.save_without_validation!
    end
    render :text => "count:" + of_data_json['news'].length.to_s
  end

  def jobs
    Job.destroy_all ""
    of_file = open("/tmp/FoundryDumpJob.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    Job.record_timestamps = false
    of_data_json['jobs'].each do |item|
      job = Job.new(item)
      job.save_without_validation!
    end
    render :text => "count:" + of_data_json['jobs'].length.to_s
  end
  
  def citations
    Citation.destroy_all ""
    of_file = open("/tmp/FoundryDumpCitation.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    Citation.record_timestamps = false
    of_data_json['citations'].each do |item|
      citation = Citation.new(item)
      citation.save_without_validation!
    end
    render :text => "count:" + of_data_json['citations'].length.to_s
  end
end

