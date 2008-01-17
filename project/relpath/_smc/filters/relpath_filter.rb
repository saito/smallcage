module SmallCage
  class RelpathFilter

    def initialize(opts)
    end

    def after_rendering_filter(obj, str)
      relpath = "../" * (obj["dirs"].size - 1)
      return str.gsub(%r{="/}, "=\"#{relpath}")
    end

  end
end