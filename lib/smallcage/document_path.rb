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
      
      if @path.to_s[0...@root.to_s.length] != @root.to_s
        raise "Illegal path: #{path.to_s}"
      end
      
      if @path == @root
        @uri = "/"
      else
        @uri = @path.to_s[@root.to_s.length .. -1]
      end
    end
    
    def smc?
      return @path.extname == ".smc"
    end
    
    def outfile
      return nil unless smc?
      return self.class.new(@root, @path.to_s[0 .. -5])
    end
    
    def outuri
      return nil unless smc?
      return uri[0 .. -5]
    end

    def self.to_uri(root, path)
      return self.new(root,path).uri
    end

    def self.create_with_uri(root, uri, base = nil)
      base ||= root
      if uri[0] == ?/
        path = root + uri[1..-1] # absolute URI
      else
        path = base + uri # relative URI
      end
      return self.new(root, path)
    end

    def self.add_smc_method(obj, value)
      obj.instance_eval do
        @__smallcage ||= {}
        @__smallcage[:smc] = value
      end

      def obj.smc
        return @__smallcage.nil? ? nil : @__smallcage[:smc]
      end

      return obj
    end


  end
end
