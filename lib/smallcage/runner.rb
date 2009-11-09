module SmallCage
  class Runner
    def self.run(opts)
      Runner.new(opts).send(opts[:command])
    end

    def initialize(opts)
      @opts = opts
      require_command "base"
    end
    
    def update
      require_command "update"
      SmallCage::Commands::Update.execute(@opts)
    end
    
    def clean
      require_command "clean"
      SmallCage::Commands::Clean.execute(@opts)
    end
    
    def server
      require_command "server"
      SmallCage::Commands::Server.execute(@opts)
    end

    def auto
      require_command "auto"
      SmallCage::Commands::Auto.execute(@opts)
    end
    
    def import
      require_command "import"
      SmallCage::Commands::Import.execute(@opts)
    end
    
    def manifest
      require_command "manifest"
      SmallCage::Commands::Manifest.execute(@opts)
    end
    
    def export
      require_command "export"
      SmallCage::Commands::Export.execute(@opts)
    end

    def uri
      require_command "uri"
      SmallCage::Commands::Uri.execute(@opts)
    end

    def require_command(name)
      require "smallcage/commands/#{name}.rb"
    end
  end
end
