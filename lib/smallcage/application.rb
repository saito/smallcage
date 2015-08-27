# Parse command-line arguments and run application.
class SmallCage::Application
  require 'English'

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
    SmallCage::OptionsParser.new(argv).parse
  end
end
