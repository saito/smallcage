module SmallCage
  class Runner
    def self.run(opts)
      Runner.new(opts).send(opts[:command])
    end

    def initialize(opts)
      @opts = opts
    end
    
    def update
      require 'smallcage/commands/update'
      SmallCage::Commands::Update.execute(@opts)
    end
    
    def clean
      require 'smallcage/commands/clean'
      SmallCage::Commands::Clean.execute(@opts)
    end
    
    def server
      require 'smallcage/commands/server'
      SmallCage::Commands::Server.execute(@opts)
    end

    def auto
      require 'smallcage/commands/auto'
      SmallCage::Commands::Auto.execute(@opts)
    end
    
    def import
      require 'smallcage/commands/import'
      SmallCage::Commands::Import.execute(@opts)
    end
    
    def manifest
      require 'smallcage/commands/manifest'
      SmallCage::Commands::Manifest.execute(@opts)
    end

  end
end