require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = Dir.glob("test/**/test_*.rb")
end

desc "Run tests"
task :default => :test