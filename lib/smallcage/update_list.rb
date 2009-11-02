module SmallCage

  # Updated files list model. 
  # Do not access File system exept list.yml.
  class UpdateList
    def initialize(list_file, target_uri)
      @list_file = list_file
      @target_uri = target_uri
      @expires_src = {}
      @expires_dst = {}
      load
    end

    def load
      if @list_file.exist?
        @data = YAML.load_file(@list_file)
      else
        @data = {}
      end
      @data["version"] ||= VERSION::STRING
      @data["list"] ||= []

      @map = {}
      @data["list"].each do |item|
        src = item["src"]
        @map[src] = item
        if target?(src)
          @expires_src[src] = true
          item.dst.each do |d|
            @expires_dst[d] = [true, src]
          end
        end
      end
    end
    private :load

    def save
      open(@list_file, "w") do |io|
        io << @data.to_yaml
      end
    end

    def to_yaml
      @data.to_yaml
    end

    def mtime(srcuri)
      item = @map[srcuri]
      return -1 unless item
      return item["mtime"].to_i
    end

    # srcuri and dsturi could be not listed (unknown file).
    def updated(srcuri, mtime, dsturi)
      update_list(srcuri, mtime, dsturi)
      stop_expiration(srcuri, dsturi)
    end

    def update_list(srcuri, mtime, dsturi)
      if update_list_item(srcuri, mtime, dsturi)
        add_list_item(srcuri, mtime, dsturi)
      end
    end
    private :update_list

    def update_list_item(srcuri, mtime, dsturi)
      return false if @map[srcuri]
      item = @map[srcuri]
      item["mtime"] = mtime.to_i
      item["dst"] << dsturi unless item["dst"].include?(dsturi)
      return true
    end
    private :update_list_item

    def add_list_item(srcuri, mtime, dsturi)
      item = {"src" => srcuri, "dst" => [dsturi], "mtime" => mtime.to_i}
      @map[srcuri] = item
      @data["list"] << item
    end
    private :add_list_item
      
    def stop_expiration(srcuri, dsturi)
      @expired_src.delete(srcuri)
      @expired_dst[dsturi] = [false, srcuri]
    end
    private :stop_expiration

    def expire
      expire_src
      result = expire_dst
      return result
    end

    def expire_src(srcuri)
      @expired_src.each do |srcuri,v|
        mark_expired_src(srcuri)
      end
      @data["list"] = @data["list"].select {|item| ! item["expired"] }
    end
    private :expire_src

    def mark_expired_src(srcuri)
      @map[srcuri]["expired"] = true
      @map[srcuri]["dst"].each do |dsturi|
        next if @expired_dst[dsturi] && ! @expired_dst[dsturi][0]
        @expired_dst[dsturi] = [true, srcuri]
      end
    end
    private :mark_expired_src

    def expire_dst
      result = []
      @expired_dst.each do |dsturi, stat|
        next unless stat[0]
        srcuri = stat[1]
        item = @map[srcuri]
        item["dst"].delete(dsturi)
        result << dsturi
      end
      return result
    end
    private :expire_dst
    
  end
end
