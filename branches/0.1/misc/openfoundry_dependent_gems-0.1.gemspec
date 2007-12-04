Gem::Specification.new do |s|
  s.name = %q{openfoundry_dependent_gems}
  s.version = "0.1"
  s.date = %q{2007-11-1}
  s.summary = %q{OpenFoundry dependent gems.}
  s.email = %q{contact@openfoundry.org}
  s.homepage = %q{http://www.openfoundry.org}
  s.rubyforge_project = %q{openfoundry}
  s.description = %q{OpenFoundry dependent gems.}
#  s.default_executable = %q{rails}
  s.authors = ["OpenFoundry team"]
  s.files = []
  s.rdoc_options = ["--exclude", "."]
#  s.executables = ["rails"]

#luors@test01:~$ gem list | ruby -ne 'puts "  s.add_dependency(%q<#{$1}>, [\"= #{$2}\"])" if /^(\S+).*\((.*?)\)/'
  s.add_dependency(%q<actionmailer>, ["= 1.3.5"])
  s.add_dependency(%q<actionpack>, ["= 1.13.5"])
  s.add_dependency(%q<actionwebservice>, ["= 1.2.5"])
  s.add_dependency(%q<activerecord>, ["= 1.15.5"])
#  s.add_dependency(%q<ActiveRecord-JDBC>, ["= 0.5"])
  s.add_dependency(%q<activesupport>, ["= 1.4.4"])
  s.add_dependency(%q<acts_as_ferret>, ["= 0.4.1"])
  s.add_dependency(%q<ferret>, ["= 0.11.4"])
  s.add_dependency(%q<gettext>, ["= 1.10.0"])
  s.add_dependency(%q<json>, ["= 1.1.1"])
  s.add_dependency(%q<rails>, ["= 1.2.5"])
  s.add_dependency(%q<rake>, ["= 0.7.3"])
#  s.add_dependency(%q<ruby-debug-base>, ["= 0.9.3"])
#  s.add_dependency(%q<ruby-debug-ide>, ["= 0.1.9"])
#  s.add_dependency(%q<sources>, ["= 0.0.1"])

end
