module SmallCage
  module BaseHelper
    include ERB::Util

    # Glob files with regular expression.
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
      entries.each do |entry|
        result << entry if entry.to_s =~ rex
      end
      return result.sort
    end

    # Switch current smc object and execute block.
    #
    #   <%- docroot = dirs.first["path"]
    #       _with(_load(docroot + "/company_001.html.smc")) do -%>
    #         name: <%= name %><br />
    #         address: <%= address %>
    #   <%- end -%>
    # 
    def _with(new_obj)
      @obj, old_obj = new_obj, @obj
      yield
    ensure
      @obj = old_obj
    end
    
    # Load smc file.
    #
    #   docroot = dirs.first["path"]
    #   item = _load(docroot + "/items/001.html.smc")
    #
    def _load(path)
      path = Pathname.new(path)
      @loader.load(path)
    end
    
    # Evaluate ERB source.
    def _erb(source)
      @renderer.render_string(source, @obj)
    end
    
    # Capture ERB output.
    #
    #   def cdata(&block)
    #     src = _capture(&block)
    #     @erbout << "<![CDATA[" + src.gsub(/\]\]>/,"]]]]><![CDATA[>") + "]]>"  
    #   end
    #
    #   <%- cdata do -%>
    #      <<< Here is CDATA section. >>>
    #   <%- end -%>
    #
    def _capture(*args, &block)
      @erbout, old_erbout = "", @erbout
      block.call(*args)
      return @erbout
    ensure
      @erbout = old_erbout
    end
    
    # Get value of
    #  - smc object
    #  - or directory config (_dir.smc)
    #  - or nil
    def _get(name, obj = @obj)
      return obj[name] if obj[name]
      return _dir(name, obj)
    end

    # Return nearest parent directory config(_dir.smc) value. 
    def _dir(name, obj = @obj)
      obj["dirs"].reverse.each do |dir|
        return dir[name] if dir[name]
      end
      return nil
    end
    
  end
end
