if RUBY_VERSION >= '1.9.3'
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

SPEC_DATA_DIR = File.join(File.dirname(__FILE__), 'data')

# required to execute rcov rake task.
require 'rspec/core'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
