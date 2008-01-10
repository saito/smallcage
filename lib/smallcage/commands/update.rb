module SmallCage::Commands
  class Update
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
      renderer = SmallCage::Renderer.new(loader)
      
      loader.each_smc_obj do |obj|
        result = renderer.render(obj["template"], obj)
              
        filters = loader.filters("after_rendering_filters")
        filters.each do |f|
          result = f.after_rendering_filter(obj, result)
        end

        output_result(obj, result)
        puts obj["uri"] if @opts[:quiet].nil?
      end
    end
    
    def output_result(obj, str)
      open(obj["path"], "w") do |io|
        io << str
      end
    end
    private :output_result
  end
end