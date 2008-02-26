module SmallCage
  module RedclothHelper
    require "redcloth"
    
    def render_redcloth(str)
      RedCloth.new(str).to_html
    end
    
  end
end