module SmallCage::Commands
  class Manifest
    def self.execute(opts)
      new(opts).execute
    end

    def initialize(opts)
      @opts = opts
    end

    def execute
      entries = []
      root = Pathname.new(@opts[:path])
      Dir.chdir(root) do
        Dir.glob('**/*') do |f|
          entries << f
        end
      end

      tmp = []
      entries.each do |f|
        path = root + f
        f = './' + f
        f = f + '/' if path.directory?
        next if path.basename.to_s == 'Manifest.html'
        tmp << f
      end
      entries = tmp

      template = File.dirname(__FILE__) + '/../resources/Manifest.erb'
      source = ERB.new(File.read(template), nil, '-').result(binding)
      open(root + 'Manifest.html', 'w') do |io|
        io << source
      end
    end
  end
end
