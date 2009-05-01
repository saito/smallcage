class SmallCage::Renderer

  def initialize(loader)
    @loader = loader
  end

  def render(name, obj)
    path = @loader.template_path(name)
    return nil if path.nil?
    return render_string(path.read, obj)
  end
    
  def render_string(str, obj)
    begin
      erb_class = ERB.new(str, nil, '-').def_class(@loader.erb_base, "erb")
      result = erb_class.new(@loader, self, obj).erb
    rescue => e
      STDERR.puts "Can't render: #{obj["uri"]}"
      raise e
    end
    return result
  end

end
