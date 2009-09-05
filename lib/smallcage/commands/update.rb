module SmallCage::Commands
  class Update
    def self.execute(opts)
      self.new(opts).execute
    end
    
    def initialize(opts)
      @opts = opts
    end
    
    def execute
      start = Time.now
      target = Pathname.new(@opts[:path])
      unless target.exist?
        raise "target directory or file does not exist.: " + target.to_s
      end
      
      @loader = SmallCage::Loader.new(target)
      @renderer = SmallCage::Renderer.new(@loader)

      urilist = render_smc_files
      rendered = urilist.length
      if list_file.exist?
        urilist = delete_expired_files(urilist)
      end
      save_list(urilist)
      elapsed = Time.now - start
      
      puts "-- #{rendered} files.  #{"%.3f" % elapsed} sec.  #{"%.3f" % (elapsed/rendered)} sec/file." unless @opts[:quiet]
    end

    def render_smc_files
      urilist = []
      @loader.each_smc_obj do |obj|
        urilist << obj["uri"].smc
        mark = obj["path"].exist? ? "U " : "A "
        render_smc_obj(obj)
        puts mark + obj["uri"] unless @opts[:quiet]
      end
      return urilist
    end
    private :render_smc_files

    def render_smc_obj(obj)
      result = @renderer.render(obj["template"], obj)
      result = after_rendering_filters(obj, result)
      output_result(obj, result)
    end
    private :render_smc_obj

    def delete_expired_files(urilist)
      old_urilist = load_list
      root = @loader.root
      target_uri = SmallCage::DocumentPath.new(root, @loader.target).uri

      if @loader.target.file?
        old_urilist << target_uri unless old_urilist.include?(target_uri)
        return old_urilist
      end
      
      target_uris = []
      not_target_uris = []
      old_urilist.each do |uri|
        if uri.index(target_uri) == 0
          target_uris << uri
        else
          not_target_uris << uri
        end
      end
      
      deletelist = target_uris - urilist

      deletelist.each do |uri|
        delfile = SmallCage::DocumentPath.new(root, root + ("." + uri)).outfile
        next unless delfile.path.file?
        
        File.delete(delfile.path)
        puts "D #{delfile.uri}" unless @opts[:quiet]
      end
      
      return (not_target_uris + urilist).sort
    end
    private :delete_expired_files
    
    def after_rendering_filters(obj, result)
      filters = @loader.filters("after_rendering_filters")
      filters.each do |f|
        result = f.after_rendering_filter(obj, result)
      end
      return result
    end
    private :after_rendering_filters

    def save_list(urilist)
      f = list_file
      FileUtils.makedirs(f.parent)
      open(f, "w") do |io|
        io << "version: " + SmallCage::VERSION::STRING + "\n"
        urilist.each do |u|
          io << u + "\n"
        end
      end
    end
    private :save_list
    
    def load_list
      txt = File.read(list_file)
      result = txt.split(/\n/)
      result.shift
      return result
    end
    private :load_list

    def list_file
      @loader.root + "./_smc/tmp/list.txt"
    end
    private :list_file

    def output_result(obj, str)
      open(obj["path"], "w") do |io|
        io << str
      end
    end
    private :output_result
  end
end
