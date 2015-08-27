module SmallCage::Commands
  #
  # 'smc clean' command
  #
  class Clean
    def self.execute(opts)
      new(opts).execute
    end

    def initialize(opts)
      @opts = opts
    end

    def execute
      start = Time.now
      count = 0

      target = Pathname.new(@opts[:path])
      fail 'target directory or file does not exist.: ' + target.to_s unless target.exist?

      loader = SmallCage::Loader.new(target)
      root = loader.root
      list = SmallCage::UpdateList.create(root, target)
      uris = list.expire
      uris.each do |uri|
        file = root + uri[1..-1]
        if file.exist?
          puts "D #{uri}" unless @opts[:quiet]
          file.delete
          count += 1
        end
      end

      tmpdir = root + '_smc/tmp'
      if tmpdir.exist?
        FileUtils.rm_r(tmpdir)
        puts 'D /_smc/tmp' unless @opts[:quiet]
        count += 1
      end

      elapsed  = Time.now - start
      puts "-- #{ count } files.  #{ sprintf('%.3f', elapsed) } sec." +
        "  #{ sprintf('%.3f', count == 0 ? 0 : elapsed / count) } sec/file." unless @opts[:quiet]
    end
  end
end
