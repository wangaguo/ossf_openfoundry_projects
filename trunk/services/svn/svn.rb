require "fileutils"
require "tempfile"

FU = FileUtils::Verbose
SVN_USER = "www"
SVN_GROUP = "www"
ROOT="/svn"
REPOS = "#{ROOT}/repos"
SVNADMIN = "/usr/local/bin/svnadmin" # "/usr/bin/svnadmin" on ubuntu



# x_y : anonymous has right "x"
#       other authenticated but unspecified user has right "y"
LINK_PARENT_DIR = {
  "_"    => [],
  "_r"   => [],
  "_rw"  => [],
  "r_r"  => [ "#{ROOT}/viewvc" ],
  "r_rw" => [ "#{ROOT}/viewvc" ],
}
ALL_LINK_PARENT_DIR = LINK_PARENT_DIR.values.flatten.uniq
ALL_LINK_PARENT_DIR.each { |dir| FU.mkdir_p(dir) }
SVN_AUTH_FILE = "#{ROOT}/svn-auth-file"
SVN_ACCESS_FILE = "#{ROOT}/svn-access-file"


class Project
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

class User
  def self.each
    [ 
      ["ur", "$apr1$N2.HeV8e$RPzFJr3SM66NBszOWUJmi."],
      ["uw", "$apr1$N2.HeV8e$RPzFJr3SM66NBszOWUJmi."],
      ["un", "$apr1$N2.HeV8e$RPzFJr3SM66NBszOWUJmi."],
      ["uo", "$apr1$N2.HeV8e$RPzFJr3SM66NBszOWUJmi."],
    ].each { |u| yield(u) }
  end
end

class Authorization
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

impl_file = File.dirname(__FILE__) + "/implementation.rb"
if File.exists?(impl_file)
  puts "Requiring local implementation: #{impl_file}"
  require impl_file
end

################################################################################

#
# Project / Repository
#
Project.each do |name|
  repos = "#{REPOS}/#{name}"
  if not File.directory?(repos)
    puts "Creating a new repository for project '#{name}' at #{repos}"
    FU.mkdir_p repos
    system("#{SVNADMIN} create #{repos}")
    FU.chown_R(SVN_USER, SVN_GROUP, repos)
  end
end

#
# User / Authentication
#
def with_temp_file(final_path, mode)
  tempfile = Tempfile.new(File.basename(final_path))
  yield tempfile
  tempfile.close
  FU.chmod mode, tempfile.path
  FU.mv tempfile.path, final_path, :force => true
end

with_temp_file(SVN_AUTH_FILE, 0644) do |tempfile|
  User.each do |login, password|
    tempfile.puts "#{login}:#{password}" 
  end
end

#
# Authorization / Symlinks
#
with_temp_file(SVN_ACCESS_FILE, 0644) do |tempfile|
  Authorization.each do |a|
    tempfile.puts "[#{a[:project_name]}:/]"
    a[:specified_users].each_pair do |user, right|
      tempfile.puts "#{user} = #{right}"
    end
    tempfile.puts "* = #{a[:unspecified_users]}"
  
    # TODO: check before write?  rm while being used?
    repos = "#{REPOS}/#{a[:project_name]}"
    to_link = LINK_PARENT_DIR["#{a[:anonymous]}_#{a[:unspecified_users]}"]
    to_link.each { |lpd| FU.ln_sf(repos, "#{lpd}/#{a[:project_name]}") }
    (ALL_LINK_PARENT_DIR - to_link).each { |lpd| FU.rm_f("#{lpd}/#{a[:project_name]}") }
  end
end
