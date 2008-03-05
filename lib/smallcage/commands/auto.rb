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
      puts "SmallCage Auto Update"
      puts "-" * 60

      start_http_server unless @port.nil?

      @update_loop = true
      while @update_loop
        sleep @sleep
                
        loader = SmallCage::Loader.new(@target)

        target_files = []
        loader.each_smc_file do |f|
          mtime = File.stat(f).mtime
          if @mtimes[f] != mtime
            @mtimes[f] = mtime
            target_files << f
          end
        end
        
        next if target_files.empty?
        target_files.each do |tf|
          runner = SmallCage::Runner.new({ :path => tf })
          runner.update
        end
        
        # print "\a" # Bell
        puts "-" * 60
        update_http_server(target_files)
      end
    end
        
    def update_http_server(target_files)        
      return unless @http_server
      path = target_files.reverse.find {|p| p.basename.to_s != "_dir.smc" }
      dpath = SmallCage::DocumentPath.new(loader.root, path)
      @http_server.updated_uri = dpath.outuri
    end
    private :update_http_server

    def init_sig_handler
      shutdown_handler = Proc.new do |signal|
        @http_server.shutdown
        @update_loop = false
      end
      SmallCage::Application.add_signal_handler(["INT", "TERM"], shutdown_handler)
    end
    private :init_sig_handler

    def start_http_server 
      document_root = @opts[:path]
      port = @opts[:port]
        
      @http_server = SmallCage::HTTPServer.new(document_root, port)
      init_sig_handler
       
      Thread.new do
        @http_server.start    
      end
    end
    private :start_http_server
    
  end
end