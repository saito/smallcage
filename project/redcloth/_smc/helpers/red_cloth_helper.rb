module SmallCage
  module RedClothHelper
    require "redcloth"

    def render_textile(str)
      RedCloth.new(str).to_html
    end

  end
end
