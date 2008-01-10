module SmallCage
  class AutoUpdate
    def self.execute(opts)
      AutoUpdate.new(opts).run
    end
    
    def initialize(opts)
      @opts = opts
      @target = Pathname.new(opts[:path])
      @sleep = 1
      @mtimes = {}
    end
    
    def run
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
                
        loader = Loader.new(@target)

        do_update = false
        loader.each_smc_file do |f|
          mtime = File.stat(f).mtime
          if @mtimes[f] != mtime
            @mtimes[f] = mtime
            do_update = true
          end
        end
        
        if do_update
          runner = Runner.new({ :path => @target })
          runner.update
          print "\a"
          puts "-" * 60
        end

      end
    
    end
    
  end
end