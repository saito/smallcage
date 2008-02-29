module SmallCage::Commands
  class Export < SmallCage::Commands::Base
    def execute
      target = Pathname.new(@opts[:path])
      unless target.exist?
        raise "target directory or file does not exist.: " + target.to_s
      end
      
      out = Pathname.new(@opts[:out]).realpath
      
      loader = SmallCage::Loader.new(target)
      root = loader.root
      
      loader.each_not_smc_file do |docpath|
        dir = Pathname.new(docpath.uri).parent
        outdir = out + ("." + dir.to_s)
        FileUtils.makedirs(outdir)
        FileUtils.cp(docpath.path, outdir)
      end
    end
  end
end