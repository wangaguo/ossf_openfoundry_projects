# run with:  god -c /home/openfoundry/of/misc/openfoundry.god.rb
# 
# This is the actual config file used to keep the mongrels of
# of.openfoundry.org running.

RUBY = "/home/openfoundry/ruby/ruby/bin/ruby"
MONGREL_RAILS = "/home/openfoundry/ruby/ruby/bin/mongrel_rails"
RAILS_ROOT = "/home/openfoundry/of"
ENVIRONMENT = "production"

USER = 'openfoundry'
GROUP = 'openfoundry'

ADDRESS = '127.0.0.1'

#for internal use, like foundry_sync, sso
7998.upto(8004) do |port|
  God.watch do |w|
    w.name = "openfoundry-mongrel-#{port}"
    w.interval = 30.seconds # default      
    w.start = "#{RUBY} #{MONGREL_RAILS} start -e #{ENVIRONMENT} -c #{RAILS_ROOT} -p #{port} \
      --user #{USER} --group #{GROUP} -l #{RAILS_ROOT}/log/mongrel.#{port}.log \
      -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid  -d"
    w.stop = "#{RUBY} #{MONGREL_RAILS} stop -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid"
    w.restart = "#{RUBY} #{MONGREL_RAILS} restart -e #{ENVIRONMENT} -c #{RAILS_ROOT} -p #{port} \
      --user #{USER} --group #{GROUP} -l #{RAILS_ROOT}/log/mongrel.#{port}.log \
      -P #{RAILS_ROOT}/tmp/pids/mongrel.#{port}.pid  -d"
    w.start_grace = 10.seconds
    w.restart_grace = 10.seconds
    w.pid_file = File.join(RAILS_ROOT, "log/mongrel.#{port}.pid")
    
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
      end
      
      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_exits)
    end
    
    # restart if memory or cpu is too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.interval = 20
        c.above = 300.megabytes
        c.times = [3, 5]
      end
      
      on.condition(:cpu_usage) do |c|
        c.interval = 10
        c.above = 70.percent
        c.times = [3, 5]
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
      end
    end
  end
end
