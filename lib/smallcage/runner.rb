module SmallCage
  class Runner
    def self.run(opts)
      Runner.new(opts).send(opts[:command])
    end

    def initialize(opts)
      @opts = opts
    end
    
    def update
      target = Pathname.new(@opts[:path])
      unless target.exist?
        raise "target directory or file does not exist.: " + target.to_s
      end
      
      loader = SmallCage::Loader.new(target)
      renderer = SmallCage::Renderer.new(loader)
      
      loader.each_smc_obj do |obj|
        result = renderer.render(obj["template"], obj)
        output_result(obj, result)
        puts obj["uri"] if @opts[:quiet].nil?
      end
    end
    
    def server
      require 'smallcage/server'
      SmallCage::Server.start(@opts)
    end

    def auto
      require 'smallcage/auto_update'
      SmallCage::AutoUpdate.start(@opts)
    end

    def output_result(obj, str)
      open(obj["path"], "w") do |io|
        io << str
      end
    end
    private :output_result
  end
end