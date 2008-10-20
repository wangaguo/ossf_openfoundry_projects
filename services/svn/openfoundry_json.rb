require "rubygems"
require "json"
require "open-uri"

VCS_SUBVERSION = "2"
VCS_SUBVERSION_CLOSE = "3"

load File.dirname(__FILE__) + "/openfoundry_json.conf"

$data = open(OPENFOUNDRY_JSON_URI).read
$data = JSON.parse($data)
$unspecified_users_permission = {}
$data["projects"].each do |name, vcs|
  $unspecified_users_permission[name] = (vcs == VCS_SUBVERSION) ? "r" : ""
end


class ProjectData
  def self.each()
    $data["projects"].each do |name, vcs|
      yield name if vcs == VCS_SUBVERSION or vcs == VCS_SUBVERSION_CLOSE
    end
  end
end

class UserData
  def self.each()
    $data["users"].each { |login, password| yield login, password }
  end
end

class AuthorizationData
  def self.each()
    $data["functions"].each_pair do |project_name, u_f|
      tmp = {}
      tmp[:project_name] = project_name
      tmp[:unspecified_users] = $unspecified_users_permission[project_name]
      tmp[:anonymous] = $unspecified_users_permission[project_name]
      tmp2 = {}
      u_f.each_pair do |login, functions|
        tmp2[login] = functions["vcs_commit"] ? "rw" : ""
      end
      tmp[:specified_users] = tmp2

      yield tmp
    end
  end
end

#
# testing
#
if __FILE__ == $0
  ProjectData.each() do |name|
    puts "name: #{name}"
  end
  UserData.each() do |login, password|
    puts "login: #{login}, password: #{password}"
  end
  AuthorizationData.each() do |a|
    puts a.to_json
  end
end

