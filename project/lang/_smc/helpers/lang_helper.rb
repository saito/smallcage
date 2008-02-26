module SmallCage
  module LangHelper

    def lang
      return @obj["lang"] unless @obj["lang"].nil?
      
      if @obj["uri"] =~ %r{^/(ja|en)/}
        return $1
      end
      
      return nil
    end

    def switch_lang(code)
      @obj["uri"].gsub(%r{^/(en|ja)/}, "/#{code}/")
    end

  end
end