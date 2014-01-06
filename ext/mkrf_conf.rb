# Install syck gem only when the RUBY_VERSION >= "2.0"
# http://stackoverflow.com/questions/4596606/rubygems-how-do-i-add-platform-specific-dependency
# http://en.wikibooks.org/wiki/Ruby_Programming/RubyGems#How_to_install_different_versions_of_gems_depending_on_which_version_of_ruby_the_installee_is_using

require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb'

begin
  Gem::Command.build_args = ARGV
rescue NoMethodError
end

inst = Gem::DependencyInstaller.new
begin
  if RUBY_VERSION >= '2.0'
    inst.install 'syck'
  end
rescue
  exit(1)
end

# create dummy rakefile to indicate success
f = File.open(File.join(File.dirname(__FILE__), 'Rakefile'), 'w')
f.write("task :default\n")
f.close
