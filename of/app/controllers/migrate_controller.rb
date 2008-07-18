require 'net/http'
require 'json'
require 'pp'
class MigrateController < ApplicationController
  def projects

    url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJsonForMigrationToOF.html'
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
      #tmp += "#{p["id"]}  #{p["name"]} #{p["summary"]}" + "<br/>"
      p2 = Project.new(p)

      p2.id = p["id"]
      p2.status = Project::STATUS[:READY]

      #def p2.valid?; true; end
      p2.save_without_validation!
      tmp += p2.pretty_inspect
    end

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
  
  def references
    Reference.destroy_all ""
    of_file = open("/tmp/FoundryDumpReference.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    Reference.record_timestamps = false
    of_data_json['references'].each do |item|
      reference = Reference.new(item)
      reference.save_without_validation!
    end
    render :text => "count:" + of_data_json['references'].length.to_s
  end
  
  def events
    Event.destroy_all ""
    of_file = open("/tmp/FoundryDumpEvent.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    Event.record_timestamps = false
    of_data_json['events'].each do |item|
      event = Event.new(item)
      event.save_without_validation!
    end
    render :text => "count:" + of_data_json['events'].length.to_s
  end
  
  def downloaders
    Downloader.destroy_all ""
    of_file = open("/tmp/FoundryDumpDownloader.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close

    Downloader.record_timestamps = false
    of_data_json['downloaders'].each do |item|
      downloader = Downloader.new(item)
      downloader.save_without_validation!
    end
    render :text => "count:" + of_data_json['downloaders'].length.to_s
  end
  
  def functions
    of_file = open("/tmp/FoundryDumpFunction.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close
    html = "count:" + of_data_json['functions'].length.to_s + "<br/>"
    of_data_json['functions'].reverse_each do |item|
      check = 0
      item['functions'].each_value do |value|
        check = check + (value || 0)
      end
      if(check == 0)
        of_data_json['functions'].delete(item)
      else
      end
    end
    html += "count:" + of_data_json['functions'].length.to_s + "<br/>"
    render :text => html + of_data_json['functions'].inspect
  end
  
  def releases
    of_file = open("/tmp/FoundryDumpRelease.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close
    of_data_json['releases'].each do |item|
      
    end
    html = "count:" + of_data_json['releases'].length.to_s + "<br/>"
    render :text => html + of_data_json['releases'].inspect
  end

  def index
  end

  def users
    url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJsonForMigrationToOFUser.html?secret=jr9'

    a = Net::HTTP.get(URI.parse(url))
    #puts a
    #
    j = JSON.parse(a)
    ##require "pp"
    #pp j
    #render :text => j.pretty_inspect, :layout => false
    tmp = ''

    tmp_store = User.record_timestamps
    User.record_timestamps = false
    users = j["users"]
    users.each do |att|
      u = User.new(att)
      u.id = att["id"]
      u.salted_password = att["password"].to_s.crypt("$1$#{rand(10000)}")

      u.save_without_validation!
      tmp += u.pretty_inspect
    end
    User.record_timestamps = tmp_store

    render :text => tmp, :layout => false

  end

  private
  def migrated_project_logo_id
    return 0 unless @pid #require project id
    
    tmp = Net::HTTP.get(URI.parse("http://rt.openfoundry.org/img/project_logo/#{@pid}.gif")) 
    if tmp =~ /^GIF/ #got gif file!
      return Image.create({
        :name => "project_logo_#{@pid}",
        :meta => "image/gif",
        :commant => "migrated from old foundry",
        :data => tmp
      }).id
    else
      return 0
    end
  end
end

