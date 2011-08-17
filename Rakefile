require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

task :default => [:test, :testrails]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/xml_representer_test.rb', 'test/model_representing_test.rb', 'test/representer_test.rb', 'test/transport_test.rb', 'test/http_verbs_test.rb', 'test/integration_test.rb', 'test/json_representer_test.rb', 'test/xml_hypermedia_test.rb', 'test/hypermedia_test.rb']
  test.verbose = true
end

Rake::TestTask.new(:testrails) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/rails/*_test.rb']
  test.verbose = true
end
