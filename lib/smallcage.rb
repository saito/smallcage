$:.unshift File.dirname(__FILE__)

module SmallCage
  class Loader
  
    def self.version
      puts SmallCage.VERSION.STRING
    end

    def load(path)
      unless path.to_s[0...DOCUMENT_ROOT.length] == DOCUMENT_ROOT    
        raise "Illegal path." 
      end

      path_str = path.to_s
      obj = YAML.load_stream(path.read)
      result = {
        "template" => "default",
        "path" => path_str[DOCUMENT_ROOT.length .. -1],
        "file" => path_str,
        "dirs" => load_dirs(path)
      }
      return result if obj.nil?
      
      arr_count = 0
      str_count = 0
      
      obj.documents.each do |o|
        if o.is_a? Hash
          result = result.merge(o)
        elsif o.is_a? Array
          result["array#{arr_count}"] = o
          arr_count += 1
        else
          result["string#{str_count}"] = o.to_s
          str_count += 1
        end
      end
      
      return result
    end

    def load_dirs(path)
      result = []
      while true    
        f = path.parent + "_dir.cms"
        if f.file?
          obj = YAML.load(f.read)
          obj["path"] = path.parent.to_s[DOCUMENT_ROOT.length..-1]
          obj["path"] += "/"
          result.unshift obj
        end
        break if path.to_s == DOCUMENT_ROOT
        path = path.parent
      end
    
      return result
    end

  end
  
  class ErbBase
    def initialize(loader, renderer, obj)
      @loader, @renderer, @obj = loader, renderer, obj
    end

    def method_missing(name)
      n = name.to_s
    
      return @obj[n] unless @obj[n].nil?
      return @obj["string0"] if n == "body" && ! @obj["string0"].nil?

      # render if template file exists. or return nil.
      return @renderer.render(name, @obj)
    end
  end

  class Renderer

    def initialize(loader)
      @loader = loader
    end

    def render(name, o)
      path = template_path(name)
      return nil unless path.file?

      erb_class = ERB.new(path.read).def_class(helper_class, "erb")
      return erb_class.new(@loader, self, o).erb
    end
    
    def template_path(name)
      str = "#{TEMPLATES_DIR}/#{name}.rhtml"  
      return Pathname.new(str)
    end

    def helper_class
      result = Class.new(SmallCage::ErbBase)

      Dir.entries(HELPERS_DIR).sort.each do |h|
        next unless h =~ %r{([^/]+_helper)\.rb$}
        require "#{HELPERS_DIR}/#{h}"
        helper_name = camelize($1)
        result.class_eval("include SmallCage::#{helper_name}")
      end
      return result
    end
    
    # From active-support/inflector.rb  
    def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      if first_letter_in_uppercase
        lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      else
        lower_case_and_underscored_word.first + camelize(lower_case_and_underscored_word)[1..-1]
      end
    end
    private :camelize
  end
    
end