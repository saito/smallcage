module SmallCage::Commands
  class Uri

    def self.execute(opts)
      self.new(opts).execute
    end

    def initialize(opts)
      @opts = opts
    end

    def execute
      target = Pathname.new(@opts[:path])
      unless target.exist?
        raise "target directory or file does not exist.: " + target.to_s
      end

      @loader   = SmallCage::Loader.new(target)
      @renderer = SmallCage::Renderer.new(@loader)
      print_uris
    end

    def print_uris
      @loader.each_smc_obj do |obj|
        print_default_or_template_uris(obj)
      end
    end
    private :print_uris

    def print_default_or_template_uris(obj)
      uris = @renderer.render(obj["template"] + ".uri", obj)
      if uris
        print_uri_templates(obj, uris.split(/\r\n|\r|\n/))
      else
        puts obj["uri"]
      end
    end
    private :print_default_or_template_uris

    def print_uri_templates(obj, uris)
      uris = uris.map {|uri| uri.strip }
      base = obj['path'].parent
      uris.each_with_index do |uri, index|
        if uri.empty?
          puts ""
        else
          docpath = SmallCage::DocumentPath.create_with_uri(@loader.root, uri, base)
          puts docpath.uri
        end
      end
    end
    private :print_uri_templates
  end
end
