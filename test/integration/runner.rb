require "integration/band_representer"
require 'sinatra/runner'

class ServerRunner < Sinatra::Runner
  def app_file
    File.expand_path("../server.rb", __FILE__)
  end

  def command
    "bundle exec ruby #{app_file} -p #{port} -e production"
  end

  def ping_path # to be overwritten
    '/method'
  end

end
runner = ServerRunner.new
#at_exit { puts "killing it:"; runner.kill }

runner.run

MiniTest::Unit.after_tests do
  runner.kill
end