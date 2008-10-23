require 'mkmf'

def append_unless(path, pattern, &blk)
  found = false
  File.open(path, File::RDONLY|File::CREAT).each do |line|
    found = true if line =~ pattern
  end
  File.open(path, "a", &blk) unless found
end

load File.dirname(__FILE__) + "/svn.conf"

RUBY = Config::CONFIG["bindir"] + "/" + Config::CONFIG["RUBY_INSTALL_NAME"]

append_unless("/etc/crontab", /svn.rb/) do |f|
  f.puts "
# 
# openfoundry_svn
#
  *       *       *       *       *       root    #{RUBY} #{ROOT}/svn.rb sync >> #{ROOT}/sync.log 2>&1
  1       19      *       *       *       root    #{RUBY} #{ROOT}/svn.rb backup >> #{ROOT}/backup.log 2>&1
"
end

append_unless("/etc/newsyslog.conf", /openfoundry_sync.log/) do |f|
  f.puts "
# 
# openfoundry_svn
#
{ROOT}/sync.log           600  7     *    @T00  JC
{ROOT}/backup.log         600  7     *    @T00  JC
"
end
