module SmallCage
  class DocumentPath
    attr_reader :root, :uri, :path

    def initialize(root, path)
      @root = Pathname.new(root).realpath

      @path = Pathname.new(path)
      if @path.exist?
        @path = @path.realpath
      else
        @path = @path.cleanpath
      end

      fail "Illegal path: #{ path.to_s }" if @path.to_s[0...@root.to_s.length] != @root.to_s

      if @path == @root
        @uri = '/'
      else
        @uri = @path.to_s[@root.to_s.length .. -1]
      end
    end

    def smc?
      @path.extname == '.smc'
    end

    def outfile
      return nil unless smc?
      self.class.new(@root, @path.to_s[0 .. -5])
    end

    def outuri
      return nil unless smc?
      uri[0 .. -5]
    end

    def self.to_uri(root, path)
      new(root, path).uri
    end

    def self.create_with_uri(root, uri, base = nil)
      base ||= root
      if uri[0, 1] == '/'
        path = root + uri[1..-1] # absolute URI
      else
        path = base + uri # relative URI
      end
      new(root, path)
    end

    def self.add_smc_method(obj, value)
      obj.instance_eval do
        @__smallcage ||= {}
        @__smallcage[:smc] = value
      end

      def obj.smc
        @__smallcage.nil? ? nil : @__smallcage[:smc]
      end

      obj
    end
  end
end
