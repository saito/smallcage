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

  def execute(argv = ARGV)
    options = parse_options(argv)
    SmallCage::Runner.run(options)
  end

  def parse_options(argv)
    @argv = argv
    @options = {}

    @parser = create_main_parser
    parse_main_options

    @command_parsers = create_command_parsers
    parse_command
    parse_command_options

    @options
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

BANNER

    parser.separator "Options are:"
    parser.on("-h", "--help", "Show this help message.") do
      puts parser
      exit(true)
    end
    parser.on("-v", "--version", "Show version info.") do
      puts VERSION_NOTE
      exit(true)
    end
    
    @options[:quiet] = false
    parser.on("-q", "--quiet", "Do not print message.") do |boolean|
      @options[:quiet] = boolean
    end

    return parser
  end
  private :create_main_parser

  def parse_main_options
    @parser.order!(@argv)
  rescue OptionParser::InvalidOption => e
    $stderr.puts e.message
    exit(false)
  end
  private :parse_main_options

  def create_command_parsers
    banners = {
      :update => "smc update [path]\n",
      :clean  => "smc clean [path]\n",
      :server => "smc server [path] [port]\n",
      :auto   => "smc auto [path] [port]\n",
      :import => "smc import [name|uri]",
      :export => "smc export [path] [outputpath]",
      :help   => "smc help [command]\n",
      :uri    => "smc uri [path]\n",
      :manifest => "smc manifest [path]\n",
    }

    parsers = {}
    banners.each do |command, banner|
      parsers[command] = create_default_command_parser(banner)
    end

    parsers[:auto].on("--bell", "Ring bell after publish.") do |boolean|
      @options[:bell] = boolean
    end

    return parsers
  end
  private :create_command_parsers

  def create_default_command_parser(banner)
    parser = OptionParser.new
    parser.banner = "Usage: " + banner

    # these options can place both before and after the subcommand.
    parser.on("-h", "--help") do
      puts @parser
      exit(true)
    end
    parser.on("-v", "--version") do
      puts VERSION_NOTE
      exit(true)
    end
    parser.on("-q", "--quiet") do |boolean|
      @options[:quiet] = boolean
    end

    return parser
  end
  private :create_default_command_parser

  def parse_command
    @options[:command] = get_command

    if @options[:command].nil?
      puts @parser
      exit(false)
    end
    parser = @command_parsers[@options[:command]]
    if parser.nil?
      $stderr.puts "no such subcommand: #{@options[:command]}"
      exit(false)
    end
    parser.parse!(@argv)
  rescue OptionParser::InvalidOption => e
    $stderr.puts e.message
    exit(false)
  end
  private :parse_command


  def get_command
    commands = Hash.new {|h,k| k}
    commands.merge!({
      :up => :update,
      :sv => :server,
      :au => :auto,
    })

    command_name = @argv.shift.to_s.strip
    return nil if command_name.empty?
    return commands[command_name.to_sym]
  end
  private :get_command


  def parse_command_options
    if @options[:command] == :help
      subcmd = @argv.shift
      if subcmd.nil?
        puts @parser
      else
        puts @command_parsers[subcmd.to_sym]
      end
      exit(true)
    elsif @options[:command] == :update
      @options[:path] = @argv.shift
      @options[:path] ||= "."
    elsif @options[:command] == :server
      @options[:path] = @argv.shift
      @options[:port] = @argv.shift
      @options[:path] ||= "."
      @options[:port] ||= 80
    elsif @options[:command] == :auto
      @options[:path] = @argv.shift
      @options[:path] ||= "."
      @options[:port] = @argv.shift
      @options[:bell] ||= false
    elsif @options[:command] == :import
      @options[:from] = @argv.shift
      @options[:from] ||= "default"
      @options[:to] = @argv.shift
      @options[:to] ||= "."
    elsif @options[:command] == :export
      @options[:path] = @argv.shift
      @options[:path] ||= "."
      @options[:out] = @argv.shift
    elsif @options[:command] == :uri
      @options[:path] = @argv.shift
      @options[:path] ||= "."
    elsif @options[:command] == :manifest
      @options[:path] = @argv.shift
      @options[:path] ||= "."
    elsif @options[:command] == :clean
      @options[:path] = @argv.shift
      @options[:path] ||= "."
    end
  end
  private :parse_command_options

end
