module SmallCage
  class AnonymousLoader
    attr_reader :module, :module_names

    def initialize
      @module = Module.new
      @module_names = []
    end

    def load_match_files(dir, rex)
      return unless File.exist?(dir)

      Dir.entries(dir).sort.each do |h|
        next unless h =~ rex

        module_name = $1.camelize
        path = File.join(dir, h)
        src = File.read(path)

        @module.module_eval(src, path)
        @module_names << module_name
      end
    end

    def self.load(dir, rex)
      loader = new
      loader.load_match_files(dir, rex)
      { :module => loader.module, :names => loader.module_names }
    end
  end
end
