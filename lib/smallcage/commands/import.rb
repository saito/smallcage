module SmallCage::Commands
  class Import
    def self.execute(opts)
      self.new(opts).execute
    end
    
    def initialize(opts)
      @opts = opts
      @project_dir = Pathname.new(__FILE__) + "../../../../project"
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
      return unless confirm_entries
      @entries.each do |e|
        if e.overwrite?
          print "*"
        elsif ! e.exist?
          print "+"
        else
          print " "
        end
        puts " " + e.path
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
      
    end

    def confirm_entries
      overwrite = []
      
      puts "Create:"
      @entries.each do |e|
        if e.overwrite?
          overwrite << e
        elsif ! e.exist?
          puts "  " + e.path
        end
      end
      puts
      
      unless overwrite.empty?
        puts "Overwrite:"
        overwrite.each do |e|
          puts "  " + e.path
        end
        puts
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