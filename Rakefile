require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/roxml_representer_test.rb', 'test/model_representing_test.rb', 'test/representer_test.rb', 'test/transport_test.rb']
  test.verbose = true
end

Rake::TestTask.new(:testrails) do |test|
  test.libs << 'test'
  test.test_files = FileList['test/rails/*_test.rb']
  test.verbose = true
end
