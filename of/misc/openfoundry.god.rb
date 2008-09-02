# run with:  god -c /home/openfoundry/of/misc/openfoundry.god.rb
# 
# This is the actual config file used to keep the mongrels of
# of.openfoundry.org running.

  RUBY = "/home/openfoundry/ruby/ruby/bin/ruby"
  MONGREL_RAILS = "/home/openfoundry/ruby/ruby/bin/mongrel_rails"
  RAILS_ROOT = "/home/openfoundry/of"
  ENVIRONMENT = "production"
  #ENVIRONMENT = "development"

  USER = 'openfoundry'
  GROUP = 'openfoundry'

  ADDRESS = '127.0.0.1'

#7996,7997 for sso
#7998,7999 for foundry_sync
#8000-8005 for production 
#9000      for ferret index server
7996.upto(8005) do |port|
  God.watch do |w|
    w.group = case port
    when 7996..7997 : "openfoundry-sso"
    when 7998..7999 : "openfoundry-sync"
    else
      port % 2 == 0 ? "openfoundry-even" : "openfoundry-odd"
    end 

    w.name = "openfoundry-mongrel-#{port}"
    w.interval = 30.seconds # default      
    w.start = "#{RUBY} #{MONGREL_RAILS} start -e #{ENVIRONMENT} -c #{RAILS_ROOT} -p #{port} \
      --user #{USER} --group #{GROUP} -l #{RAILS_ROOT}/log/mongrel.#{port}.log \
      -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid  -d"
    w.stop = "#{RUBY} #{MONGREL_RAILS} stop -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid"
    w.restart = "#{RUBY} #{MONGREL_RAILS} restart -c #{RAILS_ROOT} \
      -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid" 
    w.start_grace = 5.seconds
    w.restart_grace = 5.seconds
    w.pid_file = File.join(RAILS_ROOT, "tmp/pids/mongrel.#{port}.pid")
    
    w.behavior(:clean_pid_file)
    
    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end
    
    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.notify = 'tim'
      end
      
      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.notify = 'tim'
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_exits) do |c|
        c.notify = 'ossf-dev'
      end
    end
    
    # restart if memory or cpu is too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.interval = 20
        c.above = 300.megabytes
        c.times = [3, 5]
        c.notify = 'ossf-dev'
      end
      
      on.condition(:cpu_usage) do |c|
        c.interval = 10
        c.above = 90.percent
        c.times = [3, 5]
        c.notify = 'ossf-dev'
      end
    end
    
    # lifecycle
    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 5.minute
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours

        c.notify = 'tim'
      end
    end
  end
end

God.watch do |w|
  command = "su #{USER} -c 'cd #{RAILS_ROOT};#{RUBY} #{RAILS_ROOT}/script/ferret_server -e #{ENVIRONMENT} %s'"
  w.group = "openfoundry-index-server"

  w.name = "openfoundry-ferret-server-9000"
  w.interval = 30.seconds # default      
  w.start = command % 'start'
  w.stop = command % 'stop'
  w.restart = command % "stop;#{RUBY} #{RAILS_ROOT}script/ferret_server -e #{ENVIRONMENT} start"
  w.start_grace = 20.seconds
  w.restart_grace = 20.seconds
  w.pid_file = File.join(RAILS_ROOT, "log/ferret.pid")
  
  w.behavior(:clean_pid_file)
  
  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end
  
  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.notify = 'tim'
    end
    
    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.notify = 'tim'
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_exits) do |c|
      c.notify = 'ossf-dev'
    end
  end
  
  # restart if memory or cpu is too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.interval = 20
      c.above = 50.megabytes
      c.times = [3, 5]
      c.notify = 'ossf-dev'
    end
    
    on.condition(:cpu_usage) do |c|
      c.interval = 10
      c.above = 70.percent
      c.times = [3, 5]
      c.notify = 'ossf-dev'
    end
  end
  
  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours

      c.notify = 'tim'
    end
  end
end

God::Contacts::Email.message_settings = {
  :from => 'monitor@openfoundry.org'
}

God::Contacts::Email.server_settings = {
  :address => "localhost",
  :port => 25,
  :domain => "openfoundry.org",
  :authentication => :plain
}

God.contact(:email) do |c|
  c.name = 'tim'
  c.email = 'tim@iis.sinica.edu.tw'
  c.group = 'ossf-dev'
end
God.contact(:email) do |c|
  c.name = 'lours'
  c.email = 'lcamel@iis.sinica.edu.tw'
  c.group = 'ossf-dev'
end
God.contact(:email) do |c|
  c.name = 'aguo'
  c.email = 'wangaguo@iis.sinica.edu.tw'
  c.group = 'ossf-dev'
end
God.contact(:email) do |c|
  c.name = 'thkuo'
  c.email = 'thkuo@iis.sinica.edu.tw'
  c.group = 'ossf-dev'
end


