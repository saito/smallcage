module SmallCage::Commands
  class Auto
    def self.execute(opts)
      self.new(opts).execute
    end
    
    def initialize(opts)
      @opts = opts
      @target = Pathname.new(opts[:path])
      @port = opts[:port]
      @sleep = 1
      @mtimes = {}
    end

    def execute
      puts_banner

      start_http_server unless @port.nil?
      init_sig_handler

      @loader = SmallCage::Loader.new(@target)

      # TODO update all when template or helper changed.
      
      modified_files # load @mtimes
      
      first_loop = true
      @update_loop = true
      while @update_loop
        if first_loop
          first_loop = false
          update_target
        else
          update_modified_files
        end
        sleep @sleep
      end
    end

    def modified_files
      result = []
      @loader.each_smc_file do |f|
        mtime = File.stat(f).mtime
        if @mtimes[f] != mtime
          @mtimes[f] = mtime
          result << f
        end
      end
      return result
    end
    private :modified_files
    
    def update_target
      runner = SmallCage::Runner.new({ :path => @target })
      runner.update
      puts_line
    end
    private :update_target

    def update_modified_files
      target_files = modified_files
      return if target_files.empty?
      target_files.each do |tf|
        runner = SmallCage::Runner.new({ :path => tf })
        runner.update
      end
      update_http_server(target_files)
      puts_line
    end
    private :update_modified_files
    
    def puts_banner
      puts "SmallCage Auto Update"
      puts_line
    end
    private :puts_banner
    
    def puts_line
      puts "-" * 60
      print "\a" # Bell
    end
    private :puts_line
    
    def update_http_server(target_files)
      return unless @http_server
      path = target_files.reverse.find {|p| p.basename.to_s != "_dir.smc" }
      dpath = SmallCage::DocumentPath.new(@loader.root, path)
      @http_server.updated_uri = dpath.outuri
    end
    private :update_http_server

    def init_sig_handler
      shutdown_handler = Proc.new do |signal|
        @http_server.shutdown unless @http_server.nil?
        @update_loop = false
      end
      SmallCage::Application.add_signal_handler(["INT", "TERM"], shutdown_handler)
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