require "integration/band_representer"
#require '/home/nick/projects/sinatra/test/integration_helper'
class ServerRunner# < IntegrationHelper::Server
  def app_file
    File.expand_path("../server.rb", __FILE__)
  end

  def run
    puts command
    puts  @pipe = IO.popen(command)
    sleep 2
  end

  def command
    "cd #{File.expand_path("..", __FILE__)} && bundle exec ruby #{app_file} -p 4567 -e production"
  end

  def kill
    puts "Killling : #{@pipe.pid.inspect}"
    Process.kill("KILL", @pipe.pid)
  end
end
runner = ServerRunner.new
#at_exit { puts "killing it:"; runner.kill }

runner.run

MiniTest::Unit.after_tests do
  runner.kill
end