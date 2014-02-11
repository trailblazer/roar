require "integration/band_representer"
#require '/home/nick/projects/sinatra/test/integration_helper'

require 'open-uri'

class ServerRunner# < IntegrationHelper::Server
  def app_file
    File.expand_path("../server.rb", __FILE__)
  end

  def run
    #puts command
    @pipe     = start
    @started  = Time.now
    warn "#{server} up and running on port #{port}" if ping
  end

  def command
    "bundle exec ruby #{app_file} -p #{port} -e production"
  end

  def kill
    return unless pipe
    Process.kill("KILL", pipe.pid)
  rescue NotImplementedError
    system "kill -9 #{pipe.pid}"
  rescue Errno::ESRCH
  end

private
  attr_accessor :pipe

  def start
    IO.popen(command)
  end

  def ping(timeout=30)
    loop do
      return if alive?
      if Time.now - @started > timeout
        $stderr.puts command, log
        fail "timeout"
      else
        sleep 0.1
      end
    end
  end

  def alive?
    3.times { get(ping_path) }
    true
  rescue Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError, SystemCallError, OpenURI::HTTPError, Timeout::Error
    false
  end

  def get(url)
    Timeout.timeout(1) { open("http://127.0.0.1:#{port}#{url}").read }
  end

  def log
    @log ||= ""
    loop { @log <<  @pipe.read_nonblock(1) }
  rescue Exception
    @log
  end

  def ping_path # to be overwritten
    '/method'
  end

  def port
    4567
  end
end
runner = ServerRunner.new
#at_exit { puts "killing it:"; runner.kill }

runner.run

MiniTest::Unit.after_tests do
  runner.kill
end