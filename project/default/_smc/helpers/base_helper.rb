module SmallCage
  module BaseHelper
    def _glob(relpath, rex)
      base_dir = Pathname.new(@obj["path"]).parent
      base_dir = base_dir.join(relpath)

      entries = Dir.glob("#{base_dir}/**/*")
      result = []
      entries.each do |path|
        result << path if path.to_s =~ rex
      end
      return result.sort
    end

    def _with(o)
      tmpobj = @obj
      @obj = o
      yield
      @obj = tmpobj
    end
    
    def _load(path)
      path = Pathname.new(path)
      @loader.load(path)
    end
    
    def _erb(body)
      @renderer.render_string(body, @obj)
    end
    
  end
end
