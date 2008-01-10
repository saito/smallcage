module SmallCage
  class Runner
    def self.run(opts)
      Runner.new(opts).send(opts[:command])
    end

    def initialize(opts)
      @opts = opts
    end
    
    def update
      require 'smallcage/update'
      SmallCage::Update.execute(@opts)
    end
    
    def server
      require 'smallcage/server'
      SmallCage::Server.execute(@opts)
    end

    def auto
      require 'smallcage/auto_update'
      SmallCage::AutoUpdate.execute(@opts)
    end
    
    def import
      require 'smallcage/import'
      SmallCage::Import.execute(@opts)
    end

  end
end