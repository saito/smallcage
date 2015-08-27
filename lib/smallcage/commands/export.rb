module SmallCage::Commands
  class Export < SmallCage::Commands::Base
    def execute
      target = Pathname.new(@opts[:path])
      fail target.to_s + ' does not exist.' unless target.exist?

      loader = SmallCage::Loader.new(target)
      root = loader.root

      if @opts[:out].nil?
        out = root + ('./_smc/tmp/export/' + Time.now.strftime('%Y%m%d%H%M%S'))
      else
        out = Pathname.new(@opts[:out])
      end
      fail out.to_s + ' already exist.' if out.exist?

      FileUtils.makedirs(out)
      out = out.realpath

      # TODO: create empty directories
      loader.each_not_smc_file do |docpath|
        dir = Pathname.new(docpath.uri).parent
        outdir = out + ('.' + dir.to_s)
        FileUtils.makedirs(outdir)
        FileUtils.cp(docpath.path, outdir)
        puts 'A ' + docpath.uri unless quiet?
      end

      unless quiet?
        puts ''
        puts 'All contents exported to:'
        puts " #{out.to_s}"
      end
    end
  end
end
