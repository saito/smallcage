module SmallCage::Commands
  class Clean
    def self.execute(opts)
      self.new(opts).execute
    end
    
    def initialize(opts)
      @opts = opts
    end
    
    def execute
      target = Pathname.new(@opts[:path])
      unless target.exist?
        raise "target directory or file does not exist.: " + target.to_s
      end
      
      loader = SmallCage::Loader.new(target)
      loader.each_smc_obj do |obj|
        if obj["path"].exist?
          obj["path"].delete 
          puts "remove: " + obj["uri"]
        end
      end
      
      tmpdir = loader.root + "./_smc/tmp"
      if tmpdir.exist?
        FileUtils.rm_r(tmpdir)
        puts "remove: /_smc/tmp"
      end
    end
  end
end