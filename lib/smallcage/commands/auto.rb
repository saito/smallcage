module SmallCage::Commands
  class Auto
    def self.execute(opts)
      self.new(opts).execute
    end
    
    def initialize(opts)
      @opts = opts
      @target = Pathname.new(opts[:path])
      @sleep = 1
      @mtimes = {}
    end
    
    def execute
      puts "SmallCage Auto Update"
      puts "-" * 60

      ['INT', 'TERM'].each do |signal|
        Signal.trap(signal) do
          puts
          puts "exit."
          exit
        end
      end
    
      loop do
        sleep @sleep
                
        loader = SmallCage::Loader.new(@target)

        do_update = false
        loader.each_smc_file do |f|
          mtime = File.stat(f).mtime
          if @mtimes[f] != mtime
            @mtimes[f] = mtime
            do_update = true
          end
        end
        
        if do_update
          runner = SmallCage::Runner.new({ :path => @target })
          runner.update
          print "\a"
          puts "-" * 60
        end

      end
    
    end
    
  end
end