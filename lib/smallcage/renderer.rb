class SmallCage::Renderer
  attr_reader :current_templates

  def initialize(loader)
    @loader = loader
    @current_templates = []
  end

  def render(name, obj)
    path = @loader.template_path(name)
    return nil if path.nil?
    @current_templates.push path
    result = render_string(path.read, obj)
    @current_templates.pop
    return result
  end
    
  def render_string(str, obj)
    erb_class = ERB.new(str, nil, '-', '@erbout').def_class(@loader.erb_base, "erb")
    return erb_class.new(@loader, self, obj).erb
  rescue Exception => e
    raise e.exception("Can't render: #{obj["uri"]}: #{e.message}")
  end

end
