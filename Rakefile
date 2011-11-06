require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

task :default => [:test, :testrails]

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/*_test.rb'] - ['test/integration_test.rb']
  test.verbose = true
end

Rake::TestTask.new(:testrails) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/rails/*_test.rb']
  test.verbose = true
end
