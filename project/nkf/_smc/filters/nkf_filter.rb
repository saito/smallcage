require "nkf"

module SmallCage

  # In _dir.smc or other *.smc, set charset like this:
  # 
  #   charset: Shift_JIS
  #   
  class NkfFilter

    def initialize(opts)
    end

    def after_rendering_filter(obj, str)
      charset = ""
      if obj["charset"]
        charset = obj["charset"]
      else
        obj["dirs"].reverse.each do |dir|
          if dir["charset"]
            charset = dir["charset"]
            break
          end
        end
      end

      opt = ""
      if charset =~ /^euc-jp$/i
        opt = "-Wem0"
      elsif charset =~ /^iso-2022-jp$/i
        opt = "-Wjm0"
      elsif charset =~ /^shift_jis$/i
        opt = "-Wsm0"
      else
        STDERR.puts "Unknown charset: #{charset}" unless charset.empty? 
        return str
      end      
      
      return NKF.nkf(opt, str)
    end

  end
end