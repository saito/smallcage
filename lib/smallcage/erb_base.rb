
class SmallCage::ErbBase
  def initialize(loader, renderer, obj)
    @loader, @renderer, @obj = loader, renderer, obj
  end

  def method_missing(*args)
    if 1 < args.length
      raise NameError.new("method_missing called with more than one argument: template:#{@renderer.current_templates.to_a.last} args:#{args.inspect}")
    end

    name = args[0].to_s
    return @obj[name] unless @obj[name].nil?

    # render if template file exists. or return nil.
    return @renderer.render(name, @obj)
  end
end
