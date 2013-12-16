#! /usr/bin/ruby

Dir.chdir File.dirname(__FILE__)
require 'net/smtp'
require 'optparse'
VCS_GIT = "4"

def send_email(from, to, subject, message)
  msg = <<END_OF_MESSAGE
From: #{from}
To: #{to.join(",")}
Subject: #{subject}

#{message}
END_OF_MESSAGE

  Net::SMTP.start('localhost') do |smtp|
    smtp.send_message msg, from, to
  end 
end  

def run_git(command)
  puts hr = %x[#{command + " 2>&1"}]
  if hr =~ /(error|fatal)/
    raise hr
  end
end

# Arguments ready
options = {}
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: sync.rb [options]"

  options[:debug] = nil 
  opts.on('-d', '--debug', 'show debug message.') do |d|
    options[:debug] = true 
  end 

  options[:min] = nil 
  opts.on('-m', '--min MINUTE', 'sync data time limit') do |min|
    options[:min] = min
  end 
end
optparse.parse!
DEBUG = options[:debug]
OPT_SYNC_MIN = options[:min]

begin
  # Get sync data
  load "sync.conf"
  require_relative DATA_IMPLEMENTATION 
  
  puts "== Account process =="
  # Delete account & new account in tmp
  tmppasswd = ""
  UserData.each do |login, password|
    hr = %x[htpasswd -D #{GIT_AUTH_FILE} #{login}] 
    tmppasswd += "#{login}:#{password}\n"
  end
  # Write tmp account to auth file.
  File.open(GIT_AUTH_FILE, 'a') do |f|
    f.puts tmppasswd
  end
  
  puts "== Project conf process =="
  # GIT create conf file. Other delete conf file.
  ProjectData.each do |name, vcs|
    conf = File.join(GIT_ACCESS_PATH, "#{name}.conf")
    puts conf
    puts File.exists?(conf)
    if vcs != VCS_GIT 
      if File.exist?(conf)
        File.delete(conf)
      end
    else
      unless Dir.exist?(conf) 
        %x[touch #{conf}]
      end
    end
  end
  
  # Write permission to conf
  AuthorizationData.each do |a|
    conf = File.join(GIT_ACCESS_PATH, "#{a[:project_name]}.conf")
    perm = "repo #{a[:project_name]}\n"
    perm += "  R = @all\n"
    a[:specified_users].each_pair do |user, right|
      perm += "  #{right} = #{user}\n"
    end
    File.open(conf, 'w') do |f|
      f.puts perm 
    end
  end
  
  # gitolite-admin process
  puts "== gitolite-admin process =="
  Dir.chdir(GITOLITE_ADMIN_PATH)
  if %x[git status -s] != ""
    puts "===git add ==="
    puts %x[git add conf/repos/*]
    puts "=== git commit ==="
    run_git("sudo -u git -H git commit -a -m 'Sync with OpenFoundry.'")
    puts "=== git push ==="
    run_git("sudo -u git -H git push")
  else
    puts "No changed."
  end
rescue
  puts "Some error occur. #{$!}"
  mail_msg = "#{$!}\n\n#{$@}"
  send_email(EMAIL_FROM, DEBUG_MAIL_TO, "[Monitor] Git sync debug @", mail_msg)
end
