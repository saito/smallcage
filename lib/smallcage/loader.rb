module SmallCage
  class Loader
    DEFAULT_TEMPLATE = "default"
    DIR_PROP_FILE = "_dir.smc"
    MAX_DEPTH = 100
  
    attr_reader :root, :target, :erb_base
  
    def initialize(target)
      target = Pathname.new(target.to_s.strip.gsub(%r{(.+)/$}, '\1'))
      target = real_target(target) 

      @target = target # absolute
      @root = self.class.find_root(target) # absolute
      @templates_dir = @root + "_smc/templates"
      @helpers_dir = @root + "_smc/helpers"
      @filters_dir = @root + "_smc/filters"
      @erb_base = load_erb_base
      @filters = load_filters
    end

    # return root dir Pathname object.
    def self.find_root(path, depth = MAX_DEPTH)
      unless path.exist?
        raise "Not found: " + path.to_s 
      end
      d = path.realpath
      
      if d.file?
        d = d.parent
      end
      
      i = 0
      loop do
        if d.join("_smc").directory?
          return d
        end
        break if d.root?
        d = d.parent

        i += 1
        break if depth <= i
      end
      
      raise "Root not found: " + path
    end
  
    def load(path)
      unless path.exist?
        raise "Not found: " + path.to_s 
      end

      docpath = SmallCage::DocumentPath.new(@root, path)

      result = {}
      if path.file?
        unless docpath.smc?
          raise "Path is not smc file: " + docpath.to_s
        end

        path_smc = docpath.path
        path_out = docpath.outfile.path
        uri_smc  = docpath.uri
        uri_out  = docpath.outuri
        source_path = path_smc

        result["dirs"]     = load_dirs(path)
        result["template"] = DEFAULT_TEMPLATE
      else # directory
        path_smc = nil
        path_out = path
        uri_smc  = nil
        uri_out  = docpath.uri
        uri_out += "/" unless uri_out =~ %r{/$}
        source_path = path + DIR_PROP_FILE
        
        if source_path.file?
          path_smc = source_path
          uri_smc = SmallCage::DocumentPath.to_uri(@root, source_path)
        end
      end
      
      add_smc_method(path_out, path_smc)
      add_smc_method(uri_out, uri_smc)

      result["path"]     = path_out
      result["uri"]      = uri_out
      result["arrays"]   = []
      result["strings"]  = []

      # target is directory and _dir.smc is not exist.
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
      result = @templates_dir + "#{name}.rhtml"
      return nil unless result.file?
      return result
    end
    
    def each_smc_obj
      each_smc_file do |path|
        next if path.directory?
        next if path.basename.to_s == DIR_PROP_FILE
        obj = load(path)
        yield obj
      end
    end
    
    def each_smc_file
      if @target.directory?
        p = Pathname.new(@target)
        Dir.chdir(@target) do
          Dir.glob("**/*.smc") do |f|
            yield p + f
          end
        end
      else
        yield @target
      end
    end
    
    def each_not_smc_file
      if @target.directory?
        p = Pathname.new(@target)
        Dir.chdir(@target) do
          Dir.glob("**/*") do |f|
            f = p + f
            next if f.directory?
            next if f.to_s =~ %r{/_smc/}
            next if f.to_s =~ %r{\.smc$}
            yield SmallCage::DocumentPath.new(@root, p + f)
          end
        end
      else
        return if @target.to_s =~ %r{/_smc/}
        return if @target.to_s =~ %r{\.smc$}
        yield SmallCage::DocumentPath.new(@root, @target)
      end
    end
    
    def real_target(target)
      return target.realpath if target.directory?
      return target.realpath if target.file? and target.to_s =~ /\.smc$/ 

      tmp = Pathname.new(target.to_s + ".smc")
      return tmp.realpath if tmp.file?

      raise "Target not found: " + target.to_s
    end
    private :real_target
    
    
    def load_erb_base
      result = Class.new(SmallCage::ErbBase)
      class << result
        def include_helpers(anon_module, mod_names)
          smc_module = anon_module.const_get("SmallCage")
          mod_names.each do |name|
            helper_module = smc_module.const_get(name)
            include helper_module
          end
        end
      end
      
      helpers = load_anonymous(@helpers_dir, %r{([^/]+_helper)\.rb$})
      result.include_helpers(helpers[:module], helpers[:names])

      return result
    end
    private :load_erb_base
    
    def load_anonymous(dir, rex)
      module_names = []
      
      mod = Module.new
      Dir.entries(dir).sort.each do |h|
        next unless h =~ rex
        
        # create anonymous module.
        module_name = $1.camelize
        
        src = File.read("#{dir}/#{h}")
        begin
          mod.module_eval(src, "#{dir}/#{h}")
        rescue => ex
          puts ex.to_s # TODO show error
          load("#{dir}/#{h}", true) # try to know error line number.
          throw Exception.new("Can't load #{dir}/#{h} / line# unknown")
        end
        module_names << module_name
      end
      
      return { :module => mod, :names => module_names }
    end
    private :load_anonymous

    def filters(name)
      if @filters[name].nil?
        return []
      end
      return @filters[name]
    end
    
    def load_filters
      result = {}
      return {} unless @filters_dir.directory?
      
      filters = load_anonymous(@filters_dir, %r{([^/]+_filter)\.rb$})
      
      config = load_filters_config
      config.each do |filter_type,filter_list|
        result[filter_type] = []
        smc_module = filters[:module].const_get("SmallCage")
        filter_list.each do |fc|
          fc = { "name" => fc } if fc.is_a? String
          filter_class = smc_module.const_get(fc["name"].camelize)
          result[filter_type] << filter_class.new(fc)
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

  end
end