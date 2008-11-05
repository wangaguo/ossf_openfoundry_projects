# config.rb: Read settings and replace them into template config files.
require 'mkmf'

def append_unless(path, pattern, &blk)
  puts "Examining #{path}"
  File.open(path, File::RDONLY|File::CREAT).each do |line|
    return if line =~ pattern  # do nothing and quit
  end
  puts "Appending to #{path}"
  File.open(path, "a", &blk)
end

def open_eval(path)
  s = File.open(path).read
  s = "<<\"KKKKKK\"\n#{s}\nKKKKKK"
  eval(s).chomp
end

def replace_template(tmpl_path)
  if tmpl_path.match(/(.*)\.tmpl$/)
    puts "Replacing template #{tmpl_path} => #{$1}"
    s = open_eval(tmpl_path)
    File.open($1, "w") { |f| f.write s }
  else
    puts "Please ends with .tmpl: #{tmpl_path}"
  end
end

require 'getoptlong'
require 'rdoc/usage'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--config', '-c', GetoptLong::REQUIRED_ARGUMENT ]
)


main_config_path = File.dirname(__FILE__) + "/../etc/openfoundry_svn.conf"
opts.each do |opt, arg|
  case opt
    when '--help'
      RDoc::usage
    when '--config'
      main_config_path = arg
  end
end

if File.exist?(main_config_path)
  puts "Loading config from #{main_config_path}"
  load main_config_path
else
  puts "Please provide #{main_config_path} (you may copy it from openfoundry_svn.conf.sample then edit it)"
  exit 1
end



RUBY = Config::CONFIG["bindir"] + "/" + Config::CONFIG["RUBY_INSTALL_NAME"]

append_unless("/etc/crontab", /svn.rb/) do |f|
  f.puts "
# 
# openfoundry_svn
#
  *       *       *       *       *       root    #{RUBY} #{BIN_DIR}/svn.rb sync >> #{LOG_DIR}/sync.log 2>&1
  1       19      *       *       *       root    #{RUBY} #{BIN_DIR}/svn.rb backup >> #{LOG_DIR}/backup.log 2>&1
"
end

append_unless("/etc/newsyslog.conf", /openfoundry_svn/) do |f|
  f.puts "
# 
# openfoundry_svn
#
#{LOG_DIR}/sync.log           600  7     *    @T00  JC
#{LOG_DIR}/backup.log         600  7     *    @T00  JC
"
end

replace_template("#{ETC_DIR}/apache_svn.conf.tmpl")
replace_template("#{ETC_DIR}/apache_viewvc.conf.tmpl")
