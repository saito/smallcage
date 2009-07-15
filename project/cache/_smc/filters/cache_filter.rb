module SmallCage
  class CacheFilter

    def initialize(opts)
    end

    def after_rendering_filter(obj, str)
      str.gsub %r{(\s(?:src|href)=["'])(?!https?://)([^"']+--latest\.(?:css|js|png|gif|jpg))(["'])} do
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
      
      entry = nil
      Dir.chdir(dir) do
        entry = Dir.glob(pattern).reject {|f| f == relpath }.sort.last
      end
      return path unless entry
      
      entry = "/" + entry if path[0] == ?/ 
      return entry
    end
    private :find_latest
  end
end
