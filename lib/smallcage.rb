$:.unshift File.dirname(__FILE__)

require 'yaml'
require 'erb'
require 'pathname'

require 'smallcage/version'
require 'smallcage/runner'

module SmallCage
  class Loader
    DEFAULT_TEMPLATE = "default"
    DIR_PROP_FILE = "_dir.smc"
  
    attr_reader :root, :target
  
    def initialize(target)
      target = Pathname.new(target.to_s.strip.gsub(%r{(.+)/$}, '\1'))
      unless target.exist?
        raise "Target not found: " + target.to_s
      end
      if target.file? && target.to_s !~ /\.smc$/
        tmp = Pathname.new(target.to_s + ".smc")
        if tmp.file?
          target = tmp
        else
          raise "Target is not smc file: " + target.to_s
        end
      end

      @target = target
      @root = find_root(target)
      @templates_dir = root + "_smc/templates"
      @helpers_dir = root + "_smc/helpers"
    end
    
    def find_root(path)
      p = path
      if p.file?
        p = p.parent
      end
      
      loop do
        if p.join("_smc").directory?
          return p
        end
        break if p.root?
        p = p.parent
      end
      
      raise "Root not found: " + path
    end
  
    def load(path)
      unless path.to_s[0...@root.to_s.length] == @root.to_s
        raise "Illegal path: " + path.to_s + " / " + @root.to_s
      end
      unless path.exist?
        raise "Not found: " + path.to_s 
      end

      result = {}
      if path.file?
        # TODO pathはオブジェクトに。通常ファイル操作で使うため文字列にする理由がない。
        # 文字列にするとディレクトリ末尾に/をつけるかどうか、などを気にする必要がある。
        # ディレクトリとファイル名を単純に結合できない。
        path_str_smc = path.to_s
        path_str     = strip_ext(path)
        uri_smc      = to_uri(path)
        uri          = strip_ext(uri_smc)
        source_path  = path

        result["dirs"]     = load_dirs(path)
        result["template"] = DEFAULT_TEMPLATE
      else
        path_str_smc = nil
        path_str     = path.to_s
        uri_smc      = nil
        uri          = to_uri(path)
        uri += "/" unless uri =~ %r{/$}

        source_path = path + DIR_PROP_FILE
        if source_path.file?
          path_str_smc = source_path.to_s
          uri_smc      = to_uri(source_path)
        end
      end
      
      add_smc_method(path_str, path_str_smc)
      add_smc_method(uri, uri_smc)

      result["path"]     = path_str
      result["uri"]      = uri
      result["arrays"]   = []
      result["strings"]  = []

      return result unless source_path.exist?

      source = source_path.read
      return result if source.strip.empty?

      obj = YAML.load_stream(source)
      return result if obj.nil?
      
      obj.documents.each do |o|
        if o.is_a? Hash
          result = result.merge(o)
        elsif o.is_a? Array
          result["arrays"]  << o
        else
          result["strings"] << o.to_s
        end
      end

      return result
    end

    def load_dirs(path)
      result = []
      loop do
        path = path.parent
        result.unshift load(path)
        break if path.join("_smc").directory?
        raise "Root directory not found!" if path.root?
      end
      return result
    end

    def template_path(name)
      str = "#{@templates_dir}/#{name}.rhtml"  
      result = Pathname.new(str)
      return nil unless result.file?
      return result
    end
    
    def each_smc_file
      if @target.directory?
        Dir.glob(@target.to_s + "/**/*.smc") do |f|
          yield f
        end
      else
        yield @target.to_s
      end
    end
    
    def each_smc_obj
      each_smc_file do |f|
        path = Pathname.new(f)
        next if File.directory?(f)
        next if path.basename.to_s == DIR_PROP_FILE
        obj = load(path)
        yield obj
      end
    end


    def erb_base
      result = Class.new(SmallCage::ErbBase)

      Dir.entries(@helpers_dir).sort.each do |h|
        next unless h =~ %r{([^/]+_helper)\.rb$}
        require "#{@helpers_dir}/#{h}"
        helper_name = camelize($1)
        result.class_eval("include SmallCage::#{helper_name}")
      end
      return result
    end
    
    def strip_ext(path)
      path.to_s[0..-5]
    end
    private :strip_ext
    
    def to_uri(path)
      path.to_s[@root.to_s.length .. -1]
    end
    private :to_uri

    def add_smc_method(str, str_smc)
      def str.smc
        str_smc
      end
    end
    private :add_smc_method

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
  
  class ErbBase
    def initialize(loader, renderer, obj)
      @loader, @renderer, @obj = loader, renderer, obj
    end

    def method_missing(name)
      n = name.to_s
    
      return @obj[n] unless @obj[n].nil?
      return @obj["strings"][0] if n == "body" && ! @obj["strings"][0].nil?

      # render if template file exists. or return nil.
      return @renderer.render(name, @obj)
    end
  end

  class Renderer

    def initialize(loader)
      @loader = loader
    end

    def render(name, o)
      path = @loader.template_path(name)
      return nil if path.nil?

      erb_class = ERB.new(path.read, nil, '-').def_class(@loader.erb_base, "erb")
      return erb_class.new(@loader, self, o).erb
    end
    
  end
end