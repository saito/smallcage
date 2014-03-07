module SmallCage

  # Updated files list model.
  # Do not access File system except list.yml.
  class UpdateList
    attr_reader :update_count

    def self.create(root_path, target_path)
      docpath = DocumentPath.new(root_path, target_path)
      uri = docpath.uri
      uri += "/" if docpath.path.directory? && uri[-1] != ?/
      return self.new(root_path + "_smc/tmp/list.yml", uri)
    end

    # target_uri must be ended with / when the target is a directory.
    def initialize(list_file, target_uri)
      @list_file = list_file
      @target_uri = target_uri
      @expired_src = {}
      @expired_dst = {}
      @update_count = 0
      load
    end

    def load
      if @list_file.exist?
        @data = YAML.load_file(@list_file)
      else
        @data = {}
      end
      @data["version"] ||= VERSION
      @data["list"] ||= []

      @map = {}
      @data["list"].each do |item|
        src = item["src"]
        @map[src] = item
        if target?(src)
          @expired_src[src] = true
          item["dst"].each do |d|
            @expired_dst[d] = [true, src]
          end
        end
      end
    end
    private :load

    def target?(uri)
      return uri[0...@target_uri.length] == @target_uri
    end
    private :target?

    def save
      FileUtils.mkpath(@list_file.parent)
      @data["version"] = VERSION
      open(@list_file, "w") do |io|
        io << to_yaml
      end
    end

    def to_yaml
      return @data.to_yaml
    end

    def mtime(srcuri)
      item = @map[srcuri]
      return -1 unless item
      return item["mtime"].to_i
    end

    def update(srcuri, mtime, dsturi)
      update_list(srcuri, mtime, dsturi)
      stop_expiration(srcuri, dsturi)
      @update_count += 1
    end

    def update_list(srcuri, mtime, dsturi)
      unless update_list_item(srcuri, mtime, dsturi)
        add_list_item(srcuri, mtime, dsturi)
      end
    end
    private :update_list

    def update_list_item(srcuri, mtime, dsturi)
      return false unless @map[srcuri]
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

    def expire_src
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
