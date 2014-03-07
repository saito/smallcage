if RUBY_VERSION >= '1.9.0'
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

SPEC_DATA_DIR = File.join(File.dirname(__FILE__), 'data')

# required to execute rcov rake task.
require 'rspec/core'
