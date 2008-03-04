module SmallCage::Commands
  class Server
    def self.execute(opts)
      document_root = opts[:path]
      port = opts[:port]
      
      server = SmallCage::HTTPServer.new(document_root, port)

      SmallCage::Application.signal_handlers << Proc.new do |signal|
        server.shutdown
      end
      server.start    
    end
  end
end