#define openfoundry of website console configuration tasks
require 'erb'

namespace 'openfoundry' do
  desc 'OpenFoundry Site-wide Configure'
  namespace 'config' do

    desc 'test Configure'
    task 'test' do
      puts 'start test configure'
      replace_template('test.conf')
      puts 'done'
    end

    desc 'Database Server Configure'
    task 'db' do
      puts "\x1b[38;5;9m---start db configure---\x1b[0m"
      replace_template('config/database.yml')
      puts "\x1b[38;5;9m---done---\x1b[0m"
    end

    desc 'Memcache Server Configure'
    task 'memcache' do
      puts "\x1b[38;5;9m---start memcache configure---\x1b[0m"
      replace_template('config/initializers/session_store.rb')
      puts "\x1b[38;5;9m---done---\x1b[0m"
    end

    desc 'Stomp Server Configure'
    task 'stomp' do
      puts "\x1b[38;5;9m---start stompserver configure---\x1b[0m"
      replace_template('config/broker.yml')
#      replace_template('config/messaging.rb')
      puts "\x1b[38;5;9m---done---\x1b[0m"
    end

    desc 'Index Server Configure'
    task 'ferret' do
      puts "\x1b[38;5;9m---start ferret server configure---\x1b[0m"
      replace_template('config/ferret_server.yml')
      puts "\x1b[38;5;9m---done---\x1b[0m"
    end

    desc 'OpenFoundry Module Configure'
    task 'module' do
      puts "\x1b[38;5;9m---start module configure---\x1b[0m"
      replace_template('config/initializers/openfoundry.rb')
      puts "\x1b[38;5;9m---done---\x1b[0m"
    end

#    desc 'OpenFoundry Environment Configure'
#    task 'environment' do
#      puts "\x1b[38;5;9m---start Environment configure---\x1b[0m"
#      replace_template('config/environment.rb')
#      puts "\x1b[38;5;9m---done---\x1b[0m"
#    end

#    desc 'OpenFoundry Translation Configure'
#    task 'translation' do
#      puts "\x1b[38;5;9m---start translation configure---\x1b[0m"
#      replace_template('config/initializers/tolk.rb')
#      puts "\x1b[38;5;9m---done---\x1b[0m"
#    end

    desc 'OpenFoundry SSO Configure'
    task 'sso' do
      puts "\x1b[38;5;9m---start sso configure---\x1b[0m"
      replace_template('config/initializers/sso.rb')
      puts "\x1b[38;5;9m---done---\x1b[0m"
    end
  end
  task :config => ['config:db', 'config:memcache', 'config:sso', 'config:translation',
            'config:stomp', 'config:ferret','config:module', 'config:environment']
end

def replace_template(fname, opt ={} )
  opt = {:ext => '.erb',
         :force => true,
         :dir => File.join(RAILS_ROOT,'config'),
         :binding => get_bindings
        }.merge(opt)
  dir = File.dirname(fname) || opt[:dir]
  template = File.join(dir, File.basename(fname)+opt[:ext])
  target = File.join(dir,File.basename(fname))
 
  read_secure_binding(template,opt)

  unless(File.exist?(target) and !opt[:force])
    puts 'generate file: '+target
    puts 'use template: '+template
    File.open(target,'w+',0600) do |f| 
      f.write(ERB.new(File.open(template).read).result(opt[:binding]))
    end
  end
end

def read_secure_binding(template,opt)
  while(secure = check_missing_binding(template,opt))
    puts "please input secure binding[\x1b[38;5;13m#{secure}\x1b[0m]:"
    %x{stty -echo}
    token = STDIN.gets.chomp
    %x{stty echo}
    eval("#{secure} = '#{token}'", opt[:binding], __FILE__, __LINE__)
  end
end

def check_missing_binding(template, opt ={})
  begin
    ERB.new(File.open(template).read).result(opt[:binding])
  rescue NameError => e
    return e.name
  end
  return nil
end

def get_bindings(binding_fname = nil)
  binding_fname||='openfoundry.production.binding.rb'
  puts 'use binding file: '+binding_fname
  eval(File.open(binding_fname).read, binding, __FILE__, __LINE__)
  return binding
end
