$:.unshift(File.dirname( __FILE__)) if __FILE__ == $0

require 'yaml'
require 'erb'
require 'pathname'
require 'open-uri'
require 'fileutils'
require 'delegate'

require 'smallcage/version'

begin
  require 'syck'
rescue LoadError => e
  puts "SmallCage (#{ SmallCage::VERSION }) requires syck! Please install syck."
  puts
  puts '  $ gem install syck'
  puts
  exit 1
end

require 'smallcage/misc'
require 'smallcage/loader'
require 'smallcage/anonymous_loader'
require 'smallcage/erb_base'
require 'smallcage/renderer'
require 'smallcage/runner'
require 'smallcage/document_path'
require 'smallcage/http_server'
require 'smallcage/application'
require 'smallcage/update_list'

SmallCage::Application.execute if __FILE__ == $0
