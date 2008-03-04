
VERSION_NOTE = "SmallCage #{SmallCage::VERSION::STRING} - Lightweight CMS Package."
OPTIONS = {}
OPTIONS[:original_argv] = ARGV.clone

class SmallCage::Application
  require 'optparse'

  @@signal_handlers = []
  
  ['INT', 'TERM'].each do |signal|
    Signal.trap(signal) do
      @@signal_handlers.each do |proc|
        proc.call(signal)
      end
    end
  end
  
  def self.signal_handlers
    @@signal_handlers
  end

  def self.execute

STDOUT.sync = true

OptionParser.new do |opts|

  opts.banner =<<BANNER
Usage: #{File.basename($0)} <subcommand> [options]
#{VERSION_NOTE}
Subcommands are:
    update [path]                    Build smc contents.
    clean  [path]                    Remove files generated from *.smc source.
    server [path] [port]             Start HTTP server.
    auto   [path] [port]             Start auto update daemon.
    import [name|uri]                Import project.
    export [path] [outputpath]       Export project.
    manifest [path]                  Generate Manifest.html file.

Options are:
BANNER

  opts.separator ""
  opts.on("-h", "--help", "Show this help message.") do
    puts opts
    exit
  end
  opts.on("-v", "--version", "Show version info.") do
    puts VERSION_NOTE
    exit
  end

  subparsers = Hash.new do |h,k|
    $stderr.puts "no such subcommand: #{k}"
    exit 1
  end
  
  subparsers[:update] = OptionParser.new do |subp|
    subp.banner =<<EOT
Usage: update [PATH]
EOT
  end
  
  subparsers[:server] = OptionParser.new do |subp|
    subp.banner =<<EOT
Usage: server [PATH] [PORT]
EOT
  end

  subparsers[:auto] = OptionParser.new do |subp|
    subp.banner =<<EOT
Usage: auto [PATH]
EOT
  end

  subparsers[:generate] = OptionParser.new do |subp|
  end
  subparsers[:release] = OptionParser.new do |subp|
  end
  subparsers[:help] = OptionParser.new do |subp|
  end
  subparsers[:import] = OptionParser.new do |subp|
  end
  subparsers[:export] = OptionParser.new do |subp|
  end
  subparsers[:manifest] = OptionParser.new do |subp|
  end
  subparsers[:clean] = OptionParser.new do |subp|
  end

  commands = Hash.new {|h,k| k}
  commands.merge!({
  	:up => :update,
  	:sv => :server,
  	:au => :auto,
  	:gen => :generate,
  	:rel => :release,
  	:st => :status,
  })

  opts.order!(ARGV)
  unless ARGV.empty?
    OPTIONS[:command] = commands[ARGV.shift.to_sym]
    subparsers[OPTIONS[:command]].parse!(ARGV)
  end
  
  if OPTIONS[:command].nil?
    puts opts
    exit
  elsif OPTIONS[:command] == :help
    subcmd = ARGV.shift
    if subcmd.nil?
      puts opts
    else
      puts subparsers[subcmd.to_sym]
    end
    exit
  elsif OPTIONS[:command] == :update
    OPTIONS[:path] = ARGV.shift
    OPTIONS[:path] ||= "."
  elsif OPTIONS[:command] == :server
    OPTIONS[:path] = ARGV.shift
    OPTIONS[:port] = ARGV.shift
    OPTIONS[:path] ||= "."
    OPTIONS[:port] ||= 80
  elsif OPTIONS[:command] == :auto
    OPTIONS[:path] = ARGV.shift
    OPTIONS[:path] ||= "."
    OPTIONS[:port] = ARGV.shift
  elsif OPTIONS[:command] == :import
  	OPTIONS[:from] = ARGV.shift
  	OPTIONS[:from] ||= "default"
  	
  	OPTIONS[:to] = ARGV.shift
  	OPTIONS[:to] ||= "."
  elsif OPTIONS[:command] == :export
  	OPTIONS[:path] = ARGV.shift
  	OPTIONS[:path] ||= "."
  	
  	OPTIONS[:out] = ARGV.shift
  elsif OPTIONS[:command] == :manifest
    OPTIONS[:path] = ARGV.shift
    OPTIONS[:path] ||= "."
  elsif OPTIONS[:command] == :clean
    OPTIONS[:path] = ARGV.shift
    OPTIONS[:path] ||= "."
  end
end

SmallCage::Runner.run(OPTIONS)

end
end