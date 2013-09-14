# This is free software released into the public domain (CC0 license).

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

require File.join(File.dirname(__FILE__), 'spec/tasks')

RSpec::Core::RakeTask.new

task :default => :spec
task :release => :spec

task :spec => 'spec:fixtures:gen'
