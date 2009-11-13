require "rexml/document" 

module SmallCage
  class CacheFilter
    TARGET_EXT = %w{css js png gif jpg ico}
    TARGET_PATTERN = "**/*--latest.{#{TARGET_EXT.join(",")}}"
    TARGET_SRC_REX = %r{(["'])(?!https?://)([^"']+--latest\.(?:#{TARGET_EXT.join("|")}))(["'])}

    def initialize(opts)
    end

    def after_rendering_filter(obj, str)
      str.gsub TARGET_SRC_REX do
        pre  = $1
        path = $2
        pro  = $3
        dir  = obj["dirs"][path[0] == ?/ ? 0 : -1]["path"]
        pre + find_latest(dir, path) + pro
      end
    end

    def find_latest(dir, path)
      relpath = path[0] == ?/ ? path[1..-1] : path
      return path unless (dir + relpath).exist?
      
      rex = /^(.+)--latest(\.[^.]+)$/
      pattern    = relpath.to_s.sub(rex, '\1-*\2')
      ext = $2

      # Search largest numbered file.
      entry = nil
      Dir.chdir(dir) do
        files = []
        Dir.glob(pattern).each do |f|
          next if f == relpath
          tmppath = f[0...-ext.length]
          next unless tmppath =~ /-0*(\d+)$/
          files << [f, $1.to_i]
        end
        files.reject {|f| f == relpath }
        entry = files.sort{|a,b| a[1] <=> b[1] }.last.to_a[0]
      end
      return path unless entry
      
      entry = "/" + entry if path[0] == ?/ 
      return entry
    end
    private :find_latest

    
    # Get svn revision of file path + ".smc" or path
    def self.get_revision(path)
      smcpath = Pathname.new(path.to_s + ".smc")
      path = smcpath if smcpath.file?
      
      src = %x{svn info --xml #{path}}
      begin
        doc = REXML::Document.new(src)
        revision = doc.elements['/info/entry/commit/@revision'].value
        return revision
      rescue
        puts "Can't get revision number: #{path}"
        return "0"
      end    
    end
    
    def self.outfiles(srcfile, outfiles)
      r = srcfile.rindex("--latest")
      prefix = srcfile[0..r]
      suffix = srcfile[r + 8 .. -1]
      result = []
      outfiles.each do |f|
        if f[0..r] == prefix && f[- suffix.length .. -1] == suffix
          rev = f[r ... -suffix.length]
          if rev =~ /^-(\d+)$/
            result << [f, $1.to_i]
          end
        end
      end
      return result.sort {|a,b| a[1] <=> b[1]}
    end
    
    def self.create_cache(list, dryrun, quiet = false)
      list.each do |path|
        revision = SmallCage::CacheFilter.get_revision(path)
        to = path.pathmap("%{--latest$,-#{revision}}X%x")
        puts File.exist?(to) ? "(cache)U #{to}" : "(cache)A #{to}" unless quiet 
        begin
          FileUtils.copy(path,to) unless dryrun
        rescue => e
          puts "  ERROR: #{e} #{path} -> #{to}"
        end
      end
    end

  end
  
end
