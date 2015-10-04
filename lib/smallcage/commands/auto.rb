module SmallCage::Commands
  #
  # 'smc auto' command
  #
  class Auto < SmallCage::Commands::Base
    def initialize(opts)
      super(opts)
      @target = Pathname.new(opts[:path])
      @port = opts[:port]
      @sleep = 1
      @timestamps = {}
    end

    def load_initial_timestamps
      # load timestamps
      modified_special_files
      modified_files

      # overwrite @timestamps using list.yml to recover last update state.
      list = SmallCage::UpdateList.create(@loader.root, @target)

      list.mtimes.each do |uri, mtime|
        path = @loader.root + ".#{uri}"
        @timestamps[path] = mtime.to_i
      end
    end
    private :load_initial_timestamps

    def execute
      puts_banner

      start_http_server unless @port.nil?
      init_sig_handler

      @loader = SmallCage::Loader.new(@target)

      first_loop = true
      @update_loop = true
      while @update_loop
        if first_loop
          first_loop = false
          if @opts[:fast]
            load_initial_timestamps
            update_modified_files
          else
            update_target
          end
        else
          update_modified_files
        end
        sleep @sleep
      end
    end

    def modified_special_files
      root = @loader.root

      result = []
      Dir.chdir(root) do
        Dir.glob('_smc/{templates,filters,helpers}/*') do |f|
          f = root + f
          mtime = File.stat(f).mtime.to_i
          if @timestamps[f] != mtime
            @timestamps[f] = mtime
            result << f
          end
        end
      end

      result
    end
    private :modified_special_files

    def modified_files
      result = []
      @loader.each_smc_file do |f|
        mtime = File.stat(f).mtime.to_i
        if @timestamps[f] != mtime
          @timestamps[f] = mtime
          result << f
        end
      end
      result
    end
    private :modified_files

    def update_target
      # load timestamps
      modified_special_files
      target_files = modified_files

      runner = SmallCage::Runner.new(:path => @target, :quiet => @opts[:quiet])
      begin
        runner.update
      rescue Exception => e
        STDERR.puts e.to_s
        STDERR.puts $@[0..4].join("\n")
        STDERR.puts ':'
      end

      update_http_server(target_files)
      puts_line
      notify
    end
    private :update_target

    def update_modified_files
      reload = false
      if modified_special_files.empty?
        target_files = modified_files
      else
        # update root directory.
        target_files = [@loader.root + './_dir.smc']
        reload = true
      end

      return if target_files.empty?
      target_files.each do |tf|
        if tf.basename.to_s == '_dir.smc'
          runner = SmallCage::Runner.new(:path => tf.parent, :quiet => @opts[:quiet])
        else
          runner = SmallCage::Runner.new(:path => tf, :quiet => @opts[:quiet])
        end
        runner.update
      end

      if reload
        @http_server.reload if @http_server
      else
        update_http_server(target_files)
      end
      puts_line
      notify
    rescue Exception => e
      STDERR.puts e.to_s
      STDERR.puts $@[0..4].join("\n")
      STDERR.puts ':'
      puts_line
      notify
      notify
    end
    private :update_modified_files

    def puts_banner
      return if quiet?
      puts 'SmallCage Auto Update'
      puts "http://localhost:#{@port}/_smc/auto" unless @port.nil?
      puts
    end
    private :puts_banner

    def puts_line
      return if quiet?
      puts '-' * 60
    end
    private :puts_line

    def notify
      return unless @opts[:bell]
      print "\a" # Bell
    end
    private :notify

    def update_http_server(target_files)
      return unless @http_server
      path = target_files.find { |p| p.basename.to_s != '_dir.smc' }
      if path.nil?
        dir = target_files.shift
        dpath = SmallCage::DocumentPath.new(@loader.root, dir.parent)
        @http_server.updated_uri = dpath.uri
      else
        dpath = SmallCage::DocumentPath.new(@loader.root, path)
        @http_server.updated_uri = dpath.outuri
      end
    end
    private :update_http_server

    def init_sig_handler
      shutdown_handler = Proc.new do |signal|
        @http_server.shutdown unless @http_server.nil?
        @update_loop = false
      end
      SmallCage::Application.add_signal_handler(%w{INT TERM}, shutdown_handler)
    end
    private :init_sig_handler

    def start_http_server
      document_root = @opts[:path]
      port = @opts[:port]

      @http_server = SmallCage::HTTPServer.new(document_root, port)

      Thread.new do
        @http_server.start
      end
    end
    private :start_http_server
  end
end
