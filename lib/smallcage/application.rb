class SmallCage::Application
  require 'optparse'
  VERSION_NOTE = "SmallCage #{SmallCage::VERSION::STRING} - a simple website generator"
  
  @@signal_handlers = nil

  def self.init_signal_handlers
    @@signal_handlers = {
      "INT" => [],
      "TERM" => []
    }

    @@signal_handlers.keys.each do |signal|
      Signal.trap(signal) do
        @@signal_handlers[signal].each do |proc|
          proc.call(signal)
        end
      end
    end
  end
  
  def self.add_signal_handler(signal, handler)
    init_signal_handlers if @@signal_handlers.nil?
    signal.to_a.each do |s|
      @@signal_handlers[s] << handler
    end
  end

  def self.execute
    STDOUT.sync = true
    self.new.execute
  end

  def execute
    @options = {}
    @parser = create_main_parser
    parse_main_options
    @command_parsers = create_command_parsers
    parse_command
    parse_command_options
    SmallCage::Runner.run(@options)
  end

  def create_main_parser
    parser = OptionParser.new
    parser.banner =<<BANNER
Usage: #{File.basename($0)} <subcommand> [options]
#{VERSION_NOTE}
Subcommands are:
    update [path]                    Build smc contents.
    clean  [path]                    Remove files generated from *.smc source.
    server [path] [port]             Start HTTP server.
    auto   [path] [port]             Start auto update server.
    import [name|uri]                Import project.
    export [path] [outputpath]       Export project.
    uri    [path]                    Print URIs.
    manifest [path]                  Generate Manifest.html file.

Options are:
BANNER
    return parser
  end
  private :create_main_parser

  def parse_main_options
    @parser.separator ""
    @parser.on("-h", "--help", "Show this help message.") do
      puts @parser
      exit
    end
    @parser.on("-v", "--version", "Show version info.") do
      puts VERSION_NOTE
      exit
    end
    @parser.order!(ARGV)
  end
  private :parse_main_options

  def create_command_parsers
    parsers = Hash.new do |h,k|
      STDERR << "no such subcommand: #{k}\n"
      exit 1
    end

    banners = {
      :update => "smc update [path]\n",
      :clean  => "smc clean [path]\n",
      :server => "smc server [path] [port]\n",
      :auto   => "smc auto [path] [port]\n",
      :import => "smc import [name|uri]",
      :export => "smc export [path] [outputpath]",
      :help   => "smc help [command]\n",
      :uri    => "smc uri [path]\n",
    }
  
    banners.each do |k,v|
      parsers[k] = OptionParser.new do |cp|
        cp.banner = "Usage: " + v
      end
    end

    return parsers
  end
  private :create_command_parsers

  def parse_command
    commands = Hash.new {|h,k| k}
    commands.merge!({
      :up => :update,
      :sv => :server,
      :au => :auto,
    })

    unless ARGV.empty?
      @options[:command] = commands[ARGV.shift.to_sym]
      @command_parsers[@options[:command]].parse!(ARGV)
    end

    if @options[:command].nil?
      puts @parser
      exit
    end
  end
  private :parse_command

  def parse_command_options
    if @options[:command] == :help
      subcmd = ARGV.shift
      if subcmd.nil?
        puts @parser
      else
        puts @command_parsers[subcmd.to_sym]
      end
      exit
    elsif @options[:command] == :update
      @options[:path] = ARGV.shift
      @options[:path] ||= "."
    elsif @options[:command] == :server
      @options[:path] = ARGV.shift
      @options[:port] = ARGV.shift
      @options[:path] ||= "."
      @options[:port] ||= 80
    elsif @options[:command] == :auto
      @options[:path] = ARGV.shift
      @options[:path] ||= "."
      @options[:port] = ARGV.shift
    elsif @options[:command] == :import
      @options[:from] = ARGV.shift
      @options[:from] ||= "default"
      @options[:to] = ARGV.shift
      @options[:to] ||= "."
    elsif @options[:command] == :export
      @options[:path] = ARGV.shift
      @options[:path] ||= "."
      @options[:out] = ARGV.shift
    elsif @options[:command] == :uri
      @options[:path] = ARGV.shift
      @options[:path] ||= "."
    elsif @options[:command] == :manifest
      @options[:path] = ARGV.shift
      @options[:path] ||= "."
    elsif @options[:command] == :clean
      @options[:path] = ARGV.shift
      @options[:path] ||= "."
    end
  end
  private :parse_command_options

end
