class Mongrel::Rails::RailsHandler
  alias_method :orig_process, :process
  def process(a, b)
    open("/tmp/process.log", "a+") do |f|
      mem1 = `ps -o rss= -p #{$$}`.to_i
      orig_process(a, b)
      mem2 = `ps -o rss= -p #{$$}`.to_i
      f.write "#{mem2 - mem1} #{a.params[Mongrel::Const::PATH_INFO]}\n" if mem2 - mem1 > 1000 * 10
    end
  end
end
