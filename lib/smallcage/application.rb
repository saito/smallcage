# Parse command-line arguments and run application.
class SmallCage::Application
  require 'optparse'
  require 'English'

  VERSION_NOTE = "SmallCage #{SmallCage::VERSION} - a simple website generator"

  @signal_handlers = nil

  def self.init_signal_handlers
    @signal_handlers = {
      'INT' => [],
      'TERM' => []
    }

    @signal_handlers.keys.each do |signal|
      Signal.trap(signal) do
        @signal_handlers[signal].each do |proc|
          proc.call(signal)
        end
      end
    end
  end

  def self.add_signal_handler(signal, handler)
    init_signal_handlers if @signal_handlers.nil?
    signal.to_a.each do |s|
      @signal_handlers[s] << handler
    end
  end

  def self.execute
    STDOUT.sync = true
    new.execute
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
    parser.banner = <<BANNER
Usage: #{File.basename($PROGRAM_NAME)} [options] <subcommand> [subcommand-options]
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

    parser.separator 'Options are:'
    parser.on('-h', '--help', 'Show this help message.') do
      puts parser
      exit(true)
    end
    parser.on('-v', '--version', 'Show version info.') do
      puts VERSION_NOTE
      exit(true)
    end

    @options[:quiet] = false
    parser.on('-q', '--quiet', 'Do not print message.') do |boolean|
      @options[:quiet] = boolean
    end

    parser
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
      :update => <<EOT,
smc update [path] [options]
    path : target directory. (default:'.')
EOT

      :clean  => <<EOT,
smc clean [path] [options]
    path : target directory (default:'.')
EOT

      :server => <<EOT,
smc server [path] [port] [options]
    path : target directory (default:'.')
    port : HTTP server port number (default:8080)
EOT

      :auto   => <<EOT,
smc auto [path] [port] [options]
    path : target directory (default:'.')
    port : HTTP server port number (default:don't launch the server)
EOT

      :import => <<EOT,
smc import [name|uri] [options]
EOT

      :export => <<EOT,
smc export [path] [outputpath] [options]
EOT

      :help   => <<EOT,
smc help [command]
EOT

      :uri    => <<EOT,
smc uri [path] [options]
EOT

      :manifest => <<EOT,
smc manifest [path] [options]
EOT

    }

    parsers = {}
    banners.each do |command, banner|
      parsers[command] = create_default_command_parser(banner)
    end

    parsers[:auto].on('--bell', 'Ring bell after publishing files.') do |boolean|
      @options[:bell] = boolean
    end

    parsers
  end
  private :create_command_parsers

  def create_default_command_parser(banner)
    parser = OptionParser.new
    parser.banner = 'Usage: ' + banner
    parser.separator 'Options are:'

    # these options can place both before and after the subcommand.
    parser.on('-h', '--help', 'Show this help message.') do
      puts parser
      exit(true)
    end
    parser.on('-v', '--version', 'Show version info.') do
      puts VERSION_NOTE
      exit(true)
    end
    parser.on('-q', '--quiet', 'Do not print message.') do |boolean|
      @options[:quiet] = boolean
    end

    parser
  end
  private :create_default_command_parser

  def parse_command
    @options[:command] = command_sym

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

  # Resolve abbrev and return command name symbol.
  def command_sym
    commands = Hash.new { |h, k| k }
    commands.merge!(
      :up => :update,
      :sv => :server,
      :au => :auto
    )

    name = @argv.shift.to_s.strip
    return nil if name.empty?
    commands[name.to_sym]
  end
  private :command_sym

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
      @options[:path] ||= '.'
    elsif @options[:command] == :server
      @options[:path] = @argv.shift
      @options[:path] ||= '.'
      @options[:port] = get_port_number(8080)
    elsif @options[:command] == :auto
      @options[:path] = @argv.shift
      @options[:path] ||= '.'
      @options[:port] = get_port_number(nil)
      @options[:bell] ||= false
    elsif @options[:command] == :import
      @options[:from] = @argv.shift
      @options[:from] ||= 'default'
      @options[:to] = @argv.shift
      @options[:to] ||= '.'
    elsif @options[:command] == :export
      @options[:path] = @argv.shift
      @options[:path] ||= '.'
      @options[:out] = @argv.shift
    elsif @options[:command] == :uri
      @options[:path] = @argv.shift
      @options[:path] ||= '.'
    elsif @options[:command] == :manifest
      @options[:path] = @argv.shift
      @options[:path] ||= '.'
    elsif @options[:command] == :clean
      @options[:path] = @argv.shift
      @options[:path] ||= '.'
    end
  end
  private :parse_command_options

  def get_port_number(default)
    return default if @argv.empty?

    port = @argv.shift
    if port.to_i == 0
      $stderr.puts "illegal port number: #{port}"
      exit(false)
    end
    port.to_i
  end
  private :get_port_number
end
