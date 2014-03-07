require "nkf"

module SmallCage
  module NkfHelper

    def shift_jis(&block)
      nkf("-Wsm0", &block)
    end

    def iso_2022_jp(&block)
      nkf("-Wjm0", &block)
    end

    def euc_jp(&block)
      nkf("-Wem0", &block)
    end

    def nkf(opt, &block)
      src = _capture(&block)
      @erbout << NKF.nkf(opt, src)
    end

    def charset
      return _get("charset") || "UTF-8"
    end

    # Convert charset inside of block.
    #
    #   <%- set_charset do -%>
    #      <%= header %>
    #      <%= body %>
    #      <%= footer %>
    #   <%- end -%>
    #
    # In _dir.smc or other *.smc:
    #
    #   charset: Shift_JIS
    #
    # In header.rhtml:
    #
    #   <meta http-equiv="Content-Type" content="text/html; charset=<%= charset %>">
    #
    # If you have to edit all templates to call set_charset method,
    # you should use nkf_filter.rb instead.
    #
    def set_charset(&block)
      c = charset()
      if c =~ /^euc-jp$/i
        euc_jp(&block)
      elsif c =~ /^iso-2022-jp$/i
        iso_2022_jp(&block)
      elsif c =~ /^shift_jis$/i
        shift_jis(&block)
      else
        yield
      end
    end
  end
end
