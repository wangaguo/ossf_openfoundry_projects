STDOUT.sync = true

if not ARGV[0] =~ /sync|backup/
  puts "usage: #{$0} sync|backup"
  exit 1
end

puts ">>>> #{Time.now}"

require "fileutils"
require "tempfile"

load File.dirname(__FILE__) + "/openfoundry_svn.conf"


class ProjectData
  def self.each
    [ 
      "p1",
      "p2",
      "p3",
      "p4",
      "p5",
    ].each { |p| yield(p) }
  end
end

class UserData
  def self.each
    [ 
      ["ur", "$apr1$N2.HeV8e$RPzFJr3SM66NBszOWUJmi."],
      ["uw", "$apr1$N2.HeV8e$RPzFJr3SM66NBszOWUJmi."],
      ["un", "$apr1$N2.HeV8e$RPzFJr3SM66NBszOWUJmi."],
      ["uo", "$apr1$N2.HeV8e$RPzFJr3SM66NBszOWUJmi."],
    ].each { |u| yield(u) }
  end
end

class AuthorizationData
  # { 
  # :project_name => "p1",
  # :specified_users => { "ur" => "r", "uw" => "rw", "un" => "", ... },
  # :unspecified_users => "r",
  # :anonymous => ""
  # }
  def self.each()
    [
      {
        :project_name => "p1",
        :specified_users => { "ur" => "r", "urw" => "rw", "un" => "" },
        :unspecified_users => "",
        :anonymous => ""
      },
      {
        :project_name => "p2",
        :specified_users => { "ur" => "r", "urw" => "rw", "un" => "" },
        :unspecified_users => "r",
        :anonymous => ""
      },
      {
        :project_name => "p3",
        :specified_users => { "ur" => "r", "urw" => "rw", "un" => "" },
        :unspecified_users => "rw",
        :anonymous => ""
      },
      {
        :project_name => "p4",
        :specified_users => { "ur" => "r", "urw" => "rw", "un" => "" },
        :unspecified_users => "r",
        :anonymous => "r"
      },
      {
        :project_name => "p5",
        :specified_users => { "ur" => "r", "urw" => "rw", "un" => "" },
        :unspecified_users => "rw",
        :anonymous => "r"
      },
    ].each {|a| yield(a) }
  end
end

impl_file = (DATA_IMPLEMENTATION.include?("/") ? "" : File.dirname(__FILE__) + "/") + DATA_IMPLEMENTATION
puts "Requiring data implementation: #{impl_file}"
require impl_file

################################################################################

ALL_LINK_PARENT_DIR = LINK_PARENT_DIR.values.flatten.uniq
(ALL_LINK_PARENT_DIR + [REPOS_PARENT_DIR, BACKUP_PARENT_DIR, VIEWVC_PARENT_DIR]).each { |dir| FU.mkdir_p(dir) }

case ARGV[0]
when "sync"
  def with_temp_file(final_path, mode)
    tempfile = Tempfile.new(File.basename(final_path))
    yield tempfile
    tempfile.close
    FU.chmod mode, tempfile.path
    FU.mv tempfile.path, final_path, :force => true
  end

  #
  # Project / Repository
  #
  ProjectData.each do |name|
    repos = "#{REPOS_PARENT_DIR}/#{name}"
    if not File.directory?(repos)
      puts "Creating a new repository for project '#{name}' at #{repos}"
      FU.mkdir_p repos
      system("#{SVNADMIN} create #{repos}")
      with_temp_file("#{repos}/hooks/pre-revprop-change", 0755) do |tempfile|
        tempfile.puts "#!/bin/sh"
      end
      FU.chown_R(SVN_USER, SVN_GROUP, repos)
    end
  end
  
  #
  # User / Authentication
  #
  with_temp_file(SVN_AUTH_FILE, 0644) do |tempfile|
    UserData.each do |login, password|
      tempfile.puts "#{login}:#{password}" 
    end
  end
  
  #
  # Authorization / Symlinks
  #
  with_temp_file(SVN_ACCESS_FILE, 0644) do |tempfile|
    AuthorizationData.each do |a|
      tempfile.puts "[#{a[:project_name]}:/]"
      a[:specified_users].each_pair do |user, right|
        tempfile.puts "#{user} = #{right}"
      end
      tempfile.puts "* = #{a[:unspecified_users]}"
    
      repos = "#{REPOS_PARENT_DIR}/#{a[:project_name]}"
      to_link = LINK_PARENT_DIR["#{a[:anonymous]}_#{a[:unspecified_users]}"]
      to_link.each do |lpd|
        if not File.symlink?("#{lpd}/#{a[:project_name]}")
          FU.ln_sf(repos, "#{lpd}/#{a[:project_name]}")
        end
      end
      # TODO: rm while being used?
      (ALL_LINK_PARENT_DIR - to_link).each { |lpd| FU.rm_f("#{lpd}/#{a[:project_name]}") }
    end
  end
when "backup"
  ProjectData.each do |name|
    repos = "#{REPOS_PARENT_DIR}/#{name}"
    backup = "#{BACKUP_PARENT_DIR}/#{name}"
    puts "Backup: #{repos} => #{backup} (#{Time.now})"
    FU.rm_rf backup
    system("#{SVNADMIN} hotcopy #{repos} #{backup}")
  end
end

puts "<<<< #{Time.now}"
