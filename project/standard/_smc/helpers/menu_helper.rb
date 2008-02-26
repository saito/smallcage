module SmallCage
  module MenuHelper
    
    def menu_active(name)
      p = @obj["menu_path"]
      p ||= @obj["uri"]
      return p =~ %r{^/#{name}/} ? "active" : "inactive"
    end
    
    def menu_active_rex(rex)
      p = @obj["menu_path"]
      p ||= @obj["uri"]
      return p =~ rex ? "active" : "inactive"
    end
    
    def topic_dirs
      result = @obj["dirs"].dup
      result.reject! {|d| d["topic"].nil? }
      return result
    end
    
  end
end