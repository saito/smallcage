module SmallCage::Commands
  class Manifest
    def self.execute(opts)
      self.new(opts).execute
    end
    
    def initialize(opts)
      @opts = opts
    end
    
    def execute
      
    end
  end
end
