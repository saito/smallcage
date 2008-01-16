module SmallCage::Commands
  class Import
    def self.execute(opts)
      self.new(opts).execute
    end
    
    def initialize(opts)
      @opts = opts
      @project_dir = Pathname.new(__FILE__) + "../../../../project"
    end
    
    def qp(str = "")
      print str unless @opts[:quiet]
    end
    
    def qps(str = "")
      puts str unless @opts[:quiet]
    end
    
    def execute
      @dest = Pathname.new(@opts[:to])
      return unless @dest.directory?
    
      if @opts[:from] =~ %r{^https?://}
        import_external
      elsif @opts[:from] =~ %r{^\w+$}
        import
      else
      end
    end
    
    def import
      d = @project_dir + @opts[:from]
      return unless d.directory?
      @entries = local_entries(d)
      unless @opts[:quiet]
        return unless confirm_entries
      end
      @entries.each do |e|
        if e.overwrite?
          qp "*"
        elsif ! e.exist?
          qp "+"
        else
          qp " "
        end
        qps " " + e.path
        e.import
      end
    end
    
    def local_entries(d)
      result = []
      Dir.chdir(d) do
        Dir.glob("**/*") do |f|
          e = ImportEntry.new
          e.path = f
          e.from = d + f
          e.to = @dest + f
          result << e
        end
      end
      return result
    end
    
    def import_external
      uri = @opts[:from]
      if uri !~ %r{/$}
        uri += "/"
      end
      mfuri = uri + "Manifest.html"
      
      source = open(mfuri) {|io| io.read }
      
      files = source.scan(%r{<li><a href="(./[^"]+)">(./[^<]+)</a></li>})
      files.each do |f|
        raise "illegal path:#{f[0]},#{f[1]}" if f[0] != f[1]
        raise "illegal path:#{f[0]}" if f[0] =~ %r{/\.\.}
        path = f[0]
        if path =~ %r{/$}
          qps "mkdir: #{path}"
          (@dest + path).mkdir
        else
          qps "copy: #{path}"
          s = open(uri + path) {|io| io.read }
          open(@dest + path, "w") {|io| io << s }
        end
      end
    end

    def confirm_entries
      overwrite = []
      
      qps "Create:"
      @entries.each do |e|
        if e.overwrite?
          overwrite << e
        elsif ! e.exist?
          qps "  " + e.path
        end
      end
      qps
      
      unless overwrite.empty?
        qps "Overwrite:"
        overwrite.each do |e|
          qps "  " + e.path
        end
        qps
      end
      
      return y_or_n("Import these files?[yN]: ", false)
    end
    private :confirm_entries
    
    def y_or_n(prompt, default)
      # TODO check tty?
      loop do
        print prompt
        yn = STDIN.gets.strip
        if yn =~ /^(y|yes)$/i
          return true
        elsif yn =~ /^(n|no)$/i
          return false
        elsif yn == ""
          return default
        end
      end
    end
    private :y_or_n
    
    
    class ImportEntry
      attr_accessor :path, :from, :to

      def import
        copy_local
      end
      
      def exist?
        to.exist?
      end
      
      def overwrite?
        to.file?
      end
      
      def copy_local
        if from.directory?
          FileUtils.makedirs(to)
        else
          FileUtils.makedirs(to.parent)
          FileUtils.copy(from, to)
        end
      end
    end
  end
end