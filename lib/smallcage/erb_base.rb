
class SmallCage::ErbBase
  def initialize(loader, renderer, obj)
    @loader, @renderer, @obj = loader, renderer, obj
  end

  def method_missing(name)
    n = name.to_s
    
    return @obj[n] unless @obj[n].nil?

    # render if template file exists. or return nil.
    return @renderer.render(name, @obj)
  end
end
