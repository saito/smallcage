module SmallCage
  module BaseHelper
    include ERB::Util

    def _glob(path, rex)
      base_dir = nil
      if path.to_s[0] == ?/
        base_dir = @obj["dirs"][0]["path"]
        base_dir = base_dir.join(path[1..-1])
      else
        base_dir = @obj["dirs"].last["path"]
        base_dir = base_dir.join(path)
      end

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
