module SmallCage

  # news entry file ... YYYYMMDDHHMM.html.smc
  # archive file    ... YYYY.html.smc or YYYYMM.html.smc or YYYYMMDD.html.smc
  module NewsHelper

    def each_latest_news(amount, &block)
      i = 0
      _glob(".", %r{/\d{12}\.html\.smc$}).reverse.each do |path|
        _with(_load(path), &block)
        i += 1
        break if amount <= i
      end
    end
    
    def each_archived_news(&block)
      date = @obj["uri"].match(%r{/(\d{4})(\d{2})?(\d{2})?\.html$}).to_a
      date.shift
      date = date.join("")
      _glob(".", %r{/#{date}\d{#{12-date.length}}\.html\.smc$}).reverse.each do |path|
        _with(_load(path), &block)
      end
    end

    def news_time
      date = @obj["uri"].match(%r{/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})\.html}).to_a
      date.shift
      return Time.local(*date)
    end
    
    def news_ftime(format = "%Y-%m-%d")
      news_time().strftime(format)
    end
    
  end
end