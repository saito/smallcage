class SmallCage::Renderer
  attr_reader :current_template

  def initialize(loader)
    @loader = loader
  end

  def render(name, obj)
    path = @loader.template_path(name)
    return nil if path.nil?
    @current_template = path
    return render_string(path.read, obj)
  end

  def render_string(str, obj)
    erb_class = ERB.new(str, nil, '-', '@erbout').def_class(@loader.erb_base, "erb")
    return erb_class.new(@loader, self, obj).erb
  rescue => e
    STDERR.puts "Can't render: #{obj["uri"]}"
    raise e
  end

end
