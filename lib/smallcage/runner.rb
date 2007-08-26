module SmallCage
  class Runner
    def self.run(opts)
      Runner.new(opts).send(opts[:command])
    end

    def initialize(opts)
      @opts = opts
    end
    
    def update
      docroot = Pathname.new(@opts[:path])
      unless docroot.directory?
        raise "path is not dir: " + docroot.to_s
      end
      
      loader = SmallCage::Loader.new(docroot)
      renderer = SmallCage::Renderer.new(loader)
      
      loader.each_smc_obj do |obj|
        result = renderer.render(obj["template"], obj)
        output_result(obj, result)
      end
    end
    
    def server
      require 'smallcage/server'
      SmallCage::Server.start(@opts)
    end

    def output_result(obj, str)
      open(obj["path"], "w") do |io|
        io << str
      end
    end
    private :output_result
  end
end