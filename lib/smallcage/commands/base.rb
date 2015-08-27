module SmallCage::Commands
  #
  # smc commands base class
  #
  class Base
    def self.execute(opts)
      new(opts).execute
    end

    def initialize(opts)
      @opts = opts
    end

    def execute
    end

    def quiet?
      @opts[:quiet]
    end
  end
end
