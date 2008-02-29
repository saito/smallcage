module SmallCage
  class DocumentPath
    
    attr_reader :root, :uri, :path
    
    def initialize(root, path)
      @root = Pathname.new(root).realpath;

      @path = Pathname.new(path)
      if @path.exist?
        @path = @path.realpath
      else
        @path = @path.cleanpath
      end
      
      if @path.to_s[0...@root.to_s.length] != @root.to_s
        raise "Illegal path: #{path.to_s}"
      end

      @uri = @path.to_s[@root.to_s.length .. -1]
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

  end
end