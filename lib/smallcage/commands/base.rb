module SmallCage::Commands
  class Base
    def self.execute(opts)
      self.new(opts).execute
    end
    
    def initialize(opts)
      @opts = opts
    end
    
    def execute
    end
    
    def quiet?
      return @opts[:quiet]
    end
    
  end
end