module SmallCage
  class Runner
    def self.run(opts)
      Runner.new(opts).send(opts[:command])
    end

    def initialize(opts)
      @opts = opts
    end
    
    def update
      SmallCage::Commands::Update.execute(@opts)
    end
    
    def clean
      SmallCage::Commands::Clean.execute(@opts)
    end
    
    def server
      SmallCage::Commands::Server.execute(@opts)
    end

    def auto
      SmallCage::Commands::Auto.execute(@opts)
    end
    
    def import
      SmallCage::Commands::Import.execute(@opts)
    end
    
    def manifest
      SmallCage::Commands::Manifest.execute(@opts)
    end

  end
end