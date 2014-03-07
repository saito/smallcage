#!/usr/bin/env rake

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

desc "-> spec"
task :default => :spec

desc "-> spec"
task :test => :spec


desc "Run all specs with rcov"
RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rcov = true
  t.rcov_opts = %w{--exclude gems,spec,pkg}
end
