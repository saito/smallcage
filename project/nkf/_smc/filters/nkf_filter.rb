module SmallCage
  require "nkf"
  
  class NkfFilter

    def initialize(opts)
      @args = opts["args"]
    end

    def after_rendering_filter(obj, str)
      return NKF.nkf(@args, str)
    end

  end
end