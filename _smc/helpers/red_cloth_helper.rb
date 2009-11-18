module SmallCage
  module RedClothHelper
    require "redcloth"
    
    def render_textile(str)
      RedCloth.new(str).to_html
    end
    
    def render_markdown(str)
      RedCloth.new(str).to_html { :markdown }
    end
    
  end
end