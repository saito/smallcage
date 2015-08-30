YAML::ENGINE.yamler = 'syck' if RUBY_VERSION >= '1.9.2'

module SmallCage
  #
  # .smc file loader
  #
  class Loader
    DEFAULT_TEMPLATE = 'default'
    DIR_PROP_FILE    = '_dir.smc'
    LOCAL_PROP_FILE  = '_local.smc'
    MAX_DEPTH = 100

    attr_reader :root, :target, :erb_base, :target_template

    def initialize(target)
      target = target.to_s.strip.chomp('/')
      if target.to_s =~ %r{(.*/|\A)_smc/templates/((?:.+/)?(?:[^/]+))\.rhtml\z}
        target = Regexp.last_match[1]
        target = '.' if target == ''
        @target_template = Regexp.last_match[2]
      end
      @target = real_target(Pathname.new(target))
      @root = self.class.find_root(@target) # absolute
      @templates_dir = @root + '_smc/templates'
      @helpers_dir = @root + '_smc/helpers'
      @filters_dir = @root + '_smc/filters'
      @erb_base = load_erb_base
      @filters = load_filters
    end

    # return root dir Pathname object.
    def self.find_root(path, depth = MAX_DEPTH)
      fail "Not found: #{path}" unless path.exist?
      d = path.realpath
      d = d.parent if d.file?
      loop do
        return d if d.join('_smc').directory?
        break if d.root? || (depth -= 1) <= 0
        d = d.parent
      end
      fail "Root not found: #{path}"
    end

    def load(path)
      fail "Not found: #{path}" unless path.exist?

      docpath = DocumentPath.new(@root, path)

      if path.file?
        return load_smc_file(docpath)
      else
        return load_dir_prop(docpath)
      end
    end

    def load_smc_file(docpath)
      fail "Path is not smc file: #{docpath}" unless docpath.smc?

      result = create_base_smc_object(docpath.outfile.path, docpath.path,
                                      docpath.outuri,       docpath.uri)

      result['template'] = DEFAULT_TEMPLATE
      result['dirs']     = load_dirs(docpath.path)

      result.merge(load_yaml(docpath.path))
    end
    private :load_smc_file

    def load_dir_prop(docpath)
      path_smc = nil
      uri_smc  = nil
      uri_out  = docpath.uri
      uri_out += '/' unless uri_out[-1, 1] == '/'

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

      result
    end
    private :load_dir_prop

    def create_base_smc_object(path_out, path_smc, uri_out, uri_smc)
      result = {}
      result['arrays']   = []
      result['strings']  = []
      result['body']     = nil
      result['path']     = DocumentPath.add_smc_method(path_out, path_smc)
      result['uri']      = DocumentPath.add_smc_method(uri_out,  uri_smc)
      result
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
          result['arrays'] ||= []
          result['arrays'] << o
        else
          result['strings'] ||= []
          result['strings'] << o.to_s
        end
      end
      result['body'] ||= result['strings'][0] if result['strings']

      result
    end
    private :load_yaml

    def load_dirs(path)
      result = []
      loop do
        path = path.parent
        result.unshift load(path)
        break if path.join('_smc').directory?
        fail 'Root directory not found!' if path.root?
      end
      result
    end

    def template_path(name)
      result = @templates_dir + "#{name}.rhtml"
      return nil unless result.file?
      result
    end

    def each_smc_obj
      each_smc_file do |path|
        next if path.directory?
        next if path.basename.to_s == DIR_PROP_FILE
        next if path.basename.to_s == LOCAL_PROP_FILE
        obj = load(path)
        next if @target_template && obj['template'] != @target_template

        yield obj
      end
    end

    def each_smc_file
      if @target.directory?
        path = Pathname.new(@target)
        Dir.chdir(@target) do
          Dir.glob('**/*.smc').sort.each do |f|
            yield path + f
          end
        end
      else
        yield @target
      end
    end

    def each_not_smc_file
      if @target.directory?
        path = Pathname.new(@target)
        Dir.chdir(@target) do
          Dir.glob('**/*').sort.each do |f|
            f = path + f
            next if f.directory?
            next if f.to_s =~ %r{/_smc/}
            next if f.to_s =~ /\.smc$/
            yield DocumentPath.new(@root, path + f)
          end
        end
      else
        return if @target.to_s =~ %r{/_smc/}
        return if @target.to_s =~ /\.smc$/
        yield DocumentPath.new(@root, @target)
      end
    end

    # When the target is template, try to find source using the template.
    def each_smc_obj_using_target_template(list, &block)
      return each_smc_obj(&block) unless @target_template

      list.filter_by_template(@target_template).each do |path|
        path = @root + path[1..-1]
        next unless path.file?
        obj = load(path)
        yield obj
      end
    end

    def real_target(target)
      return target.realpath if target.directory?
      return target.realpath if target.file? && target.to_s =~ /\.smc$/

      tmp = Pathname.new(target.to_s + '.smc')
      return tmp.realpath if tmp.file?

      fail 'Target not found: ' + target.to_s
    end
    private :real_target

    def load_erb_base
      result = Class.new(ErbBase)
      class << result
        def include_helpers(anon_module, mod_names)
          smc_module = anon_module.const_get('SmallCage')
          mod_names.each do |name|
            helper_module = smc_module.const_get(name)
            include helper_module
          end
        end
      end

      helpers = SmallCage::AnonymousLoader.load(@helpers_dir, %r{([^/]+_helper)\.rb\z})
      result.include_helpers(helpers[:module], helpers[:names])

      result
    end
    private :load_erb_base

    def filters(name)
      @filters[name].nil? ? [] : @filters[name]
    end

    def load_filters
      result = {}
      return {} unless @filters_dir.directory?

      filter_modules = SmallCage::AnonymousLoader.load(@filters_dir, %r{([^/]+_filter)\.rb\z})
      smc_module = filter_modules[:module].const_get('SmallCage')

      load_filters_config.each do |filter_type, filter_list|
        result[filter_type] = []
        filter_list.to_a.each do |fc|
          fc = { 'name' => fc } if fc.is_a? String
          filter_class = smc_module.const_get(fc['name'].camelize)
          result[filter_type] << filter_class.new(fc)
        end
      end
      result
    end
    private :load_filters

    def load_filters_config
      path = @filters_dir.join('filters.yml')
      return {} unless path.file?
      YAML.load(path.read) || {}
    end
    private :load_filters_config
  end
end
