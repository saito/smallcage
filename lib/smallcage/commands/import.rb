module SmallCage::Commands
  class Import
    def self.execute(opts)
      self.new(opts).execute
    end

    def initialize(opts)
      @opts = opts
      if @opts[:from] == "default"
        @opts[:from] = "base,standard"
      end
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

      Dir.mkdir(@dest) unless @dest.exist?
      return unless @dest.directory?

      from = @opts[:from].split(/,/)
      from.each do |f|
        qps
        qps "Import: #{f}"
        if f =~ %r{^https?://}
          import_external(f)
        elsif f =~ %r{^\w+$}
          import(f)
        else
        end
      end
    end

    def import(from)
      d = @project_dir + from
      return unless d.directory?
      @entries = local_entries(d)
      unless @opts[:quiet]
        return unless confirm_entries
      end
      import_entries
    end

    def import_external
      @entries = external_entries
      unless @opts[:quiet]
        return unless confirm_entries
      end
      import_entries
    end

    def import_entries
      failed = []
      @entries.each do |e|
        if e.overwrite?
          qps "M /" + e.path
        elsif ! e.exist?
          qps "A /" + e.path
        elsif e.to.directory?
          # nothing
        else
          qps "? /" + e.path
        end

        begin
          e.import
        rescue
          failed << e
          qps "F /" + e.path
        end
      end

      unless failed.empty?
        qps "FAILED:"
        failed.each do |e|
          qps "  " + e.path
        end
      end
    end
    private :import_entries

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
    private :local_entries

    def external_entries(uri)
      if uri !~ %r{/$}
        uri += "/"
      end
      mfuri = uri + "Manifest.html"

      source = open(mfuri) {|io| io.read }
      result = []

      files = source.scan(%r{<li><a href="(./[^"]+)">(./[^<]+)</a></li>}) #"
      files.each do |f|
        raise "illegal path:#{f[0]},#{f[1]}" if f[0] != f[1]
        raise "illegal path:#{f[0]}" if f[0] =~ %r{/\.\.}
        path = f[0]
        e = ImportEntry.new
        e.path = path
        e.from = uri + path
        e.to = @dest + path
        result << e
      end

      return result
    end
    private :external_entries

    def confirm_entries
      overwrite = []

      qps "Create:"
      @entries.each do |e|
        if e.overwrite?
          overwrite << e
        elsif ! e.exist?
          qps "  /" + e.path
        end
      end
      qps

      unless overwrite.empty?
        qps "Overwrite:"
        overwrite.each do |e|
          qps "  /" + e.path
        end
        qps
      end

      return y_or_n("Import these files?[Yn]: ", true)
    end
    private :confirm_entries

    def y_or_n(prompt, default)
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
        if external?
          copy_external
        else
          copy_local
        end
      end

      def external?
        from.to_s =~ %r{^https?://}
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
      private :copy_local

      def copy_external
        if from =~ %r{/$}
          FileUtils.makedirs(to)
        else
          FileUtils.makedirs(to.parent)
          s = open(from) {|io| io.read }
          open(to, "w") {|io| io << s }
        end
      end
      private :copy_external
    end
  end
end
