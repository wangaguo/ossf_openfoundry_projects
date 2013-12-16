require "rubygems"
require "json"
require "open-uri"

$data = open(OPENFOUNDRY_JSON_URI).read
$data = JSON.parse($data)

class ProjectData
  def self.each()
    $data["projects"].each do |name, vcs|
      #yield name if vcs == VCS_GIT
      yield name, vcs
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
      tmp2 = {}
      u_f.each_pair do |login, functions|
        tmp2[login] = functions["vcs_commit"] ? "RW+" : ""
      end
      tmp[:specified_users] = tmp2

      yield tmp
    end
  end
end

#
# testing
#
if DEBUG == true 
  ProjectData.each() do |name, vcs|
    puts "name: #{name}, vcs: #{vcs}"
  end
  UserData.each() do |login, password|
    puts "login: #{login}, password: #{password}"
  end
  AuthorizationData.each() do |a|
    puts a.to_json
  end
end
