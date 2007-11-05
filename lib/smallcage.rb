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
    MAX_DEPTH = 100
  
    attr_reader :root, :target, :erb_base
  
    def initialize(target)
      target = Pathname.new(target.to_s.strip.gsub(%r{(.+)/$}, '\1'))
      target = real_target(target)

      @target = target
      @root = find_root(target, MAX_DEPTH)
      @templates_dir = root + "_smc/templates"
      @helpers_dir = root + "_smc/helpers"
      @filters_dir = root + "_smc/filters"
      @erb_base = load_erb_base
      @filters = load_filters
    end
    
    def find_root(path, depth)
      d = path
      if d.file?
        d = d.parent
      end
      
      i = 0
      loop do
        if d.join("_smc").directory?
          return d
        end
        break if d.realpath.root?
        d = d.parent

        i += 1
        break if depth <= i
      end
      
      raise "Root not found: " + path
    end
  
    def load(path)
      unless path.to_s[0...@root.to_s.length] == @root.to_s
        raise "Illegal path: " + path.to_s + " , " + @root.to_s
      end
      unless path.exist?
        raise "Not found: " + path.to_s 
      end

      result = {}
      if path.file?
        path_smc = path
        path_out = Pathname.new(strip_ext(path))
        uri_smc = to_uri(path)
        uri_out = strip_ext(uri_smc)
        source_path = path

        result["dirs"]     = load_dirs(path)
        result["template"] = DEFAULT_TEMPLATE
      else
        path_smc = nil
        path_out = path
        uri_smc = nil
        uri_out = to_uri(path)
        uri_out += "/" unless uri_out =~ %r{/$}
        source_path = path + DIR_PROP_FILE

        if source_path.file?
          path_smc = source_path
          uri_smc = to_uri(source_path)
        end
      end
      
      add_smc_method(path_out, path_smc)
      add_smc_method(uri_out, uri_smc)

      result["path"]     = path_out
      result["uri"]      = uri_out
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
    
    def real_target(target)
      return target if target.directory?
      return target if target.file? and target.to_s =~ /\.smc$/ 

      tmp = Pathname.new(target.to_s + ".smc")
      return tmp if tmp.file?

      raise "Target not found: " + target.to_s
    end
    private :real_target
    
    
    def load_erb_base
      result = Class.new(SmallCage::ErbBase)
      class_names = load_classes(@helpers_dir, %r{([^/]+_helper)\.rb$})
      class_names.each do |class_name|
        result.class_eval("include SmallCage::#{class_name}")
      end
      return result
    end
    private :load_erb_base
    
    def load_classes(dir, rex)
      class_names = []
      Dir.entries(dir).sort.each do |h|
        next unless h =~ rex
        require "#{dir}/#{h}"
        class_names << camelize($1)
      end
      return class_names
    end
    private :load_classes

    def filters(name)
      if @filters[name].nil?
        return []
      end
      return @filters[name]
    end
    
    def load_filters
      result = {}
      return {} unless @filters_dir.directory?
      
      load_classes(@filters_dir, %r{([^/]+_filter)\.rb$})
      
      config = load_filters_config
      config.each do |filter_type,filter_list|
        result[filter_type] = []
        filter_list.each do |fc|
          fc = { "name" => fc } if fc.is_a? String
          klass = SmallCage.const_get(camelize(fc["name"]))
          result[filter_type] << klass.new(fc)
        end
      end
      return result
    end
    private :load_filters

    def load_filters_config
      path = @filters_dir.join("filters.yml")
      return {} unless path.file?
      return YAML.load(path.read())
    end
    private :load_filters_config
    
    def strip_ext(path)
      path.to_s[0..-5]
    end
    private :strip_ext
    
    def to_uri(path)
      path.to_s[@root.to_s.length .. -1]
    end
    private :to_uri

    def add_smc_method(obj, value)
      obj.instance_eval do
        @__smallcage ||= {}
        @__smallcage[:smc] = value
      end

      def obj.smc
        return @__smallcage.nil? ? nil : @__smallcage[:smc]
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

    def render(name, obj)
      path = @loader.template_path(name)
      return nil if path.nil?
      return render_string(path.read, obj)
    end
    
    def render_string(str, obj)
      erb_class = ERB.new(str, nil, '-').def_class(@loader.erb_base, "erb")
      result = erb_class.new(@loader, self, obj).erb
      return result
    end

  end
  
end