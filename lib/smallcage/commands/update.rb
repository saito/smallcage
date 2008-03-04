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
      
      urilist = []
      
      loader.each_smc_obj do |obj|
        urilist << obj["uri"].smc
        
        result = renderer.render(obj["template"], obj)
        
        filters = loader.filters("after_rendering_filters")
        filters.each do |f|
          result = f.after_rendering_filter(obj, result)
        end

        output_result(obj, result)
        puts obj["uri"] if @opts[:quiet].nil?
      end
      
      listfile = loader.root + "./_smc/tmp/list.txt"
      if listfile.exist?
        txt = File.read(listfile)
        old_urilist = txt.split(/\n/)
        old_urilist.shift
        deletelist = old_urilist - urilist
        deletelist.each do |uri|
          delfile = SmallCage::DocumentPath.new(loader.root, loader.root + ("." + uri)).outfile
          if delfile.path.file?
            puts "delete: #{delfile.uri}"
            File.delete(delfile.path)
          end
        end
      end
      FileUtils.makedirs(listfile.parent)
      open(listfile, "w") do |io|
        io << "version: " + SmallCage::VERSION::STRING + "\n"
        urilist.each do |u|
          io << u + "\n"
        end
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
