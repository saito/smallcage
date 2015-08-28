module SmallCage
  #
  # Updated files list model.
  #
  # UpdateList doesn't access file system except list.yml.
  #
  class UpdateList
    attr_reader :update_count, :load_error

    def self.create(root_path, target_path)
      docpath = DocumentPath.new(root_path, target_path)
      uri = docpath.uri
      uri += '/' if docpath.path.directory? && uri[-1, 1] != '/'
      new(root_path + '_smc/tmp/list.yml', uri)
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
      @load_error = nil
      if @list_file.exist?
        begin
          @yaml = YAML.load_file(@list_file)
        rescue StandardError => e
          @load_error = e
          @yaml = {}
        end
      else
        @yaml = {}
      end
      @yaml['version'] ||= VERSION
      @yaml['list'] ||= []

      @src_item_map = {}
      @yaml['list'].each do |item|
        src = item['src']
        @src_item_map[src] = item
        if target?(src)
          @expired_src[src] = true
          item['dst'].each do |d|
            @expired_dst[d] = [true, src]
          end
        end
      end
    end
    private :load

    def target?(uri)
      uri[0...@target_uri.length] == @target_uri
    end
    private :target?

    def save
      FileUtils.mkpath(@list_file.parent)
      @yaml['version'] = VERSION
      open(@list_file, 'w') do |io|
        io << to_yaml
      end
    end

    def to_yaml
      @yaml.to_yaml
    end

    # return src_uri => mtime hash.
    def mtimes
      Hash[@src_item_map.map { |k,v| [k, v['mtime'].to_i] }]
    end

    def mtime(srcuri)
      item = @src_item_map[srcuri]
      return -1 unless item
      item['mtime'].to_i
    end

    def update(srcuri, mtime, dsturi)
      update_list(srcuri, mtime, dsturi)
      stop_expiration(srcuri, dsturi)
      @update_count += 1
    end

    def update_list(srcuri, mtime, dsturi)
      add_list_item(srcuri, mtime, dsturi) unless update_list_item(srcuri, mtime, dsturi)
    end
    private :update_list

    def update_list_item(srcuri, mtime, dsturi)
      return false unless @src_item_map[srcuri]
      item = @src_item_map[srcuri]
      item['mtime'] = mtime.to_i
      item['dst'] << dsturi unless item['dst'].include?(dsturi)
      true
    end
    private :update_list_item

    def add_list_item(srcuri, mtime, dsturi)
      item = { 'src' => srcuri, 'dst' => [dsturi], 'mtime' => mtime.to_i }
      @src_item_map[srcuri] = item
      @yaml['list'] << item
    end
    private :add_list_item

    def stop_expiration(srcuri, dsturi)
      @expired_src.delete(srcuri)
      @expired_dst[dsturi] = [false, srcuri]
    end
    private :stop_expiration

    def expire
      expire_src
      expire_dst
    end

    def expire_src
      @expired_src.each do |srcuri, v|
        mark_expired_src(srcuri)
      end
      @yaml['list'] = @yaml['list'].select { |item| !item['expired'] }
    end
    private :expire_src

    def mark_expired_src(srcuri)
      @src_item_map[srcuri]['expired'] = true
      @src_item_map[srcuri]['dst'].each do |dsturi|
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
        item = @src_item_map[srcuri]
        item['dst'].delete(dsturi)
        result << dsturi
      end
      result
    end
    private :expire_dst
  end
end
