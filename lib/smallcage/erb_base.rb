#
# ERB Base class
#
class SmallCage::ErbBase
  def initialize(loader, renderer, obj)
    @loader, @renderer, @obj = loader, renderer, obj
  end

  def method_missing(*args)
    if 1 < args.length
      msg = 'method_missing called with more than one argument: ' +
        "#{ @renderer.current_template } #{ args.inspect }"
      fail NameError, msg
    end

    name = args[0].to_s
    return @obj[name] unless @obj[name].nil?

    # render if template file exists. or return nil.
    @renderer.render(name, @obj)
  end
end
