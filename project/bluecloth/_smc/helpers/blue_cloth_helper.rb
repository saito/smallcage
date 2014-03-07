module SmallCage
  module BlueClothHelper
    require "bluecloth"

    def render_markdown(str)
      BlueCloth.new(str).to_html
    end
  end
end
