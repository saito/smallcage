module SmallCage
  class Loader
    DEFAULT_TEMPLATE = "default"
    DIR_PROP_FILE    = "_dir.smc"
    LOCAL_PROP_FILE  = "_local.smc"
    MAX_DEPTH = 100
  
    attr_reader :root, :target, :erb_base
  
    def initialize(target)
      target = Pathname.new(target.to_s.strip.chomp('/'))
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
      raise "Not found: #{path}" unless path.exist?
      d = path.realpath
      d = d.parent if d.file?
      loop do
        return d if d.join("_smc").directory?
        break if d.root? || (depth -= 1) <= 0
        d = d.parent
      end
      raise "Root not found: #{path}"
    end
  
    def load(path)
      raise "Not found: #{path}" unless path.exist?

      docpath = DocumentPath.new(@root, path)

      if path.file?
        return load_smc_file(docpath)
      else 
        return load_dir_prop(docpath)
      end
    end

    def load_smc_file(docpath)
      raise "Path is not smc file: #{docpath}" unless docpath.smc?

      result = create_base_smc_object(docpath.outfile.path, docpath.path,
                                      docpath.outuri,       docpath.uri)
      
      result["template"] = DEFAULT_TEMPLATE
      result["dirs"]     = load_dirs(docpath.path)

      return result.merge(load_yaml(docpath.path))
    end
    private :load_smc_file

    def load_dir_prop(docpath)
      path_smc = nil
      uri_smc  = nil
      uri_out  = docpath.uri
      uri_out += "/" unless uri_out[-1] == ?/

      dir_prop_file   = docpath.path + DIR_PROP_FILE
      local_prop_file = docpath.path + LOCAL_PROP_FILE
      if dir_prop_file.file?
        path_smc = dir_prop_file
        uri_smc  = DocumentPath.to_uri(@root, dir_prop_file)
      end

      result = create_base_smc_object(docpath.path, path_smc,
                                      uri_out, uri_smc)

      result.merge!(load_yaml(dir_prop_file))   if dir_prop_file.file?
      result.merge!(load_yaml(local_prop_file)) if local_prop_file.file?

      return result
    end
    private :load_dir_prop
    
    def create_base_smc_object(path_out, path_smc, uri_out, uri_smc)
      result = {}
      result["arrays"]   = []
      result["strings"]  = []
      result["body"]     = nil
      result["path"]     = DocumentPath.add_smc_method(path_out, path_smc)
      result["uri"]      = DocumentPath.add_smc_method(uri_out,  uri_smc )
      return result
    end
    private :create_base_smc_object

    def load_yaml(path)
      result = {}

      source = path.read
      return result if source.strip.empty?
      begin
        obj = YAML.load_stream(source)
        return result if obj.nil?
      rescue => e
        raise "Can't load file: #{path} / #{e}"
      end
      obj.documents.each do |o|
        case o
        when Hash
          result.merge!(o)
        when Array
          result["arrays"] ||= []
          result["arrays"]  << o
        else
          result["strings"] ||= []
          result["strings"] << o.to_s
        end
      end
      result["body"] ||= result["strings"][0] if result["strings"]

      return result
    end
    private :load_yaml

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
        next if path.basename.to_s == LOCAL_PROP_FILE
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
            yield DocumentPath.new(@root, p + f)
          end
        end
      else
        return if @target.to_s =~ %r{/_smc/}
        return if @target.to_s =~ %r{\.smc$}
        yield DocumentPath.new(@root, @target)
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
      result = { :module => mod, :names => module_names }
      
      return result unless File.exist?(dir)

      Dir.entries(dir).sort.each do |h|
        next unless h =~ rex
        
        # create anonymous module.
        module_name = $1.camelize
        
        src = File.read("#{dir}/#{h}")
        begin
          mod.module_eval(src, "#{dir}/#{h}")
        rescue => ex
          STDERR << ex.to_s # TODO show error
          load("#{dir}/#{h}", true) # try to know error line number.
          raise "Can't load #{dir}/#{h} / line# unknown"
        end
        module_names << module_name
      end
      
      return result
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
      
      filter_modules = load_anonymous(@filters_dir, %r{([^/]+_filter)\.rb$})
      smc_module = filter_modules[:module].const_get("SmallCage")
      
      load_filters_config.each do |filter_type,filter_list|
        result[filter_type] = []
        filter_list.to_a.each do |fc|
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
      return YAML.load(path.read()) || {}
    end
    private :load_filters_config
    
  end
end
