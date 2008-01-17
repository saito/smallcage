$:.unshift File.dirname(__FILE__)

require 'yaml'
require 'erb'
require 'pathname'
require 'open-uri'
require 'fileutils'

require 'smallcage/version'
require 'smallcage/misc'
require 'smallcage/loader'
require 'smallcage/erb_base'
require 'smallcage/renderer'
require 'smallcage/runner'

require 'smallcage/commands/update'
require 'smallcage/commands/clean'
require 'smallcage/commands/server'
require 'smallcage/commands/auto'
require 'smallcage/commands/import'
require 'smallcage/commands/manifest'

