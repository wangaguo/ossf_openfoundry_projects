require 'net/http'
require 'json'
require 'pp'
class MigrateController < ApplicationController
  def projects

    url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJsonForMigrationToOF.html?secret=984jfuet8kiedsi3kimkt'
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
    Project.record_timestamps = false
    projects.each do |p|
      #tmp += "#{p["id"]}  #{p["name"]} #{p["summary"]}" + "<br/>"

      p.delete("intendedaudience")
      p.delete("topic")
      p.delete("topicsuggestion")

      p2 = Project.new(p)

      p2.id = p["id"]
      p2.status = Project::STATUS[:READY]
      p2.icon = migrated_project_logo_id(p2.id)


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
 
  FUNCTION_MIGRATE_MAP = {
    'Upload' => [14,4],#['ftp_access', 'release'],
    'Members' => 2,#'project_member', 
    'Jobs' => 6,#'jobs',
    'Citations' => 7,#'citation',
    'Forum' => 12,#'sympa_manage',
    'News' => 5,#'news',
    'References' => 8,#'reference',
    'Basics' => 1#'project_info'
  }

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
        r = Role.new({:name => 'Customized Role', 
                        :authorizable_type => 'Project',
                        :authorizable_id => item['project_id']

        })
        r.users << User.find(item['name'])
        item['functions'].delete_if{|k,v| v.nil? }.each { |k,v| 
          next if k == 'CustomField'
          if Array === FUNCTION_MIGRATE_MAP[k]
            html += "#{FUNCTION_MIGRATE_MAP[k]},#{k}#######<br/>"
            r.functions << FUNCTION_MIGRATE_MAP[k].map{|n| Function.find(n)}
          else
            html += "#{FUNCTION_MIGRATE_MAP[k]}, #{k}#######<br/>"
            r.functions << Function.find(FUNCTION_MIGRATE_MAP[k])
          end
        }
        r.save
      end
    end
    html += "count:" + of_data_json['functions'].length.to_s + "<br/>"
    render :text => html #+ of_data_json['functions'].inspect
  end
  
  def releases
    of_file = open("/tmp/FoundryDumpRelease.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close
    
    Release.destroy_all ""
    Fileentity.destroy_all ""
    Release.record_timestamps = false
    Fileentity.record_timestamps = false
    status_map = {'released' => 1, 'preparing' => 0, 'empty' => -2, 'deleted' => -1}
    releaseId = ''
    release = ''
    of_data_json['releases'].each do |item|
      if(item['ticket_id'] != releaseId)
        releaseId = item['ticket_id']
        if(release != '')
          release.save_without_validation!
        end
        release = Release.new
        release.project_id = item['project_id']
        release.version = item['version']
        #release.start_date = item['start_date']
        release.due = item['ideal_release']
        #release.release_date = item['release_date']
        release.status = status_map[item['status']]
        #release.updated_by = item['r_updated_by']
        release.updated_at = item['r_updated_at']
        release.creator = item['r_created_by']
        release.created_at = item['r_created_at']
        release.save_without_validation!
      end
      if(item['filename'] != nil)
        release.release_counter += (item['download'] || 0)
        file = release.fileentity.new
        file.meta = item['transactionId'].to_s + ',' + item['attachmentId'].to_s
        file.description = item['description']
        file.size = item['size']
        file.path = item['filename']
        file.created_at = item['f_created_at']
        #file.updated_at = item['']
        file.creator = item['f_created_by']
        file.file_counter = (item['download'] || 0)
        file.save_without_validation!
      end
    end
    if(release != '')
      release.save_without_validation!
    end
    html = "count:" + of_data_json['releases'].length.to_s + "<br/>"
    render :text => html# + of_data_json['releases'].inspect
  end
  
  #count release & file
  def releases_count
    of_file = open("/tmp/FoundryDumpRelease.data")
    of_data = of_file.read
    of_data_json = JSON.parse(of_data)
    of_file.close
    
    releaseId = ''
    release_count = 0
    file_count = 0
    of_data_json['releases'].each do |item|
      if(item['ticket_id'] != releaseId)
        releaseId = item['ticket_id']
        release_count += 1
      end
      if(item['filename'] != nil)
        file_count += 1
      end
    end
    html = "data_count:" + of_data_json['releases'].length.to_s + "<br/>"
    html += "release_count:" + release_count.to_s + "<br/>"
    html += "file_count:" + file_count.to_s + "<br/>"
    render :text => html
  end

  def index
  end

  def users
    url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJsonForMigrationToOFUser.html?secret=unlkDJOIEMu7fh20ujuenks84857jdSJGIEWN00UDH'

    a = Net::HTTP.get(URI.parse(url))
    #puts a
    #
    j = JSON.parse(a)
    ##require "pp"
    #pp j
    #render :text => j.pretty_inspect, :layout => false
    #tmp = ''

    #tmp_store = User.record_timestamps
    #User.record_timestamps = false
    #users = j["users"]
    #users.each do |att|
    #  privacy = att.delete('privacy')
    #  #u = User.new(att)
    #  u = User.find_by_login(att['login'])
    #  u.language =
    #  if att['language'] == 'zh-tw'
    #    'zh_TW' 
    #  else
    #    'en'
    #  end
    #  #u.id = att["id"]
    #  #u.icon = migrated_user_logo_id(att['id'], att['login'])
    #  #u.salted_password = att["password"].to_s.crypt("$1$#{rand(10000)}")
    #  #u.timezone = 'Taipei'
    #  #u.verified = 1
    #  #if privacy
    #  #  u.t_conseal_email    = true unless privacy['Email']
    #  #  u.t_conseal_bio      = true unless privacy['Itro']
    #  #  u.t_conseal_realname = true unless privacy['RealName']
    #  #  u.t_conseal_homepage = true unless privacy['PersonalHomepage']
    #  #else
    #  #  u.t_conseal_email    = true
    #  #  u.t_conseal_bio      = true
    #  #  u.t_conseal_realname = true 
    #  #  u.t_conseal_homepage = true
    #  #end

    #  u.save_without_validation!
    #  #tmp += u.pretty_inspect
    #end
    #User.record_timestamps = tmp_store
    
    #migrate relations:{'admin': [[pid,uid]...],'member':...}
    relations = j["relations"]
    insert_sql = "insert into roles_users(user_id,role_id) values "
    insert_values_array = []
    relations['admin'].each do |pair|
      pid, uid = pair[0], pair[1]
      r=Role.find_or_create_by_name_and_authorizable_type_and_authorizable_id(
        :name => 'Admin', :authorizable_type => 'Project', :authorizable_id => pid)
      r.functions << Function.find(:all)
      r.save!
      project_role_id = r.id
      insert_values_array << "('#{uid}','#{project_role_id}')" 
    end
    relations['member'].each do |pair|
      pid, uid = pair[0], pair[1]
      project_role_id = Role.find_or_create_by_name_and_authorizable_type_and_authorizable_id(
        :name => 'Member', :authorizable_type => 'Project', :authorizable_id => pid).id
      insert_values_array << "('#{uid}','#{project_role_id}')" 
    end
    Role.connection.execute(insert_sql + insert_values_array.join(','))
    #render :text => tmp, :layout => false
    
  end

  private
  def migrated_user_logo_id(id,login_name)
    begin
      f = File.new("tmp/user_icon/#{login_name}.icon")   
      return Image.create({
        :name => "user_logo_#{id}",
        :meta => `file -i -b tmp/user_icon/#{login_name}.icon`.strip!,
        :comment => "migrated from old foundry",
        :data => f.read
      }).id
    rescue
    ensure
      f.close if f
    end
    
    return 0 
    #filename = icon[2].gsub(/([^a-zA-Z0-9_.-]+)/n) do
    #  '%' + $1.unpack('H2' * $1.size).join('%').upcase
    #end

    #contenttype = icon[3].to_s.gsub('\/','/')

    #tmp = Net::HTTP.get(URI.parse(
    #"http://rt.openfoundry.org/Work/Tickets/Attachment/#{icon[0]}/#{icon[1]}/#{filename}"))
    #return Image.create({
    #  :name => "user_logo_#{id}",
    #  :meta => contenttype,
    #  :comment => "migrated from old foundry",
    #  :data => tmp
    #}).id
  end
  
  def migrated_project_logo_id(pid)
    return 0 unless pid #require project id
    
    #tmp = Net::HTTP.get(URI.parse("http://rt.openfoundry.org/img/project_logo/#{pid}.gif")) 
    tmp = ""
    begin
      f = File.new("/tmp/project_logo/#{pid}.gif")
      tmp = f.read

      s = `file /tmp/project_logo/#{pid}.gif`
      s = s.match(/(\w+)\simage/)[1]
      return Image.create({
        :name => "project_logo_#{pid}",
        :meta => "image/#{s}",
        :comment => "migrated from old foundry",
        :data => tmp
      }).id
    rescue
        f.close if f
    end 

    return 0
  end
end

