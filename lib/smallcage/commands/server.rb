module SmallCage::Commands
  class Server
    def self.execute(opts)
      document_root = opts[:path]
      port = opts[:port]

      server = SmallCage::HTTPServer.new(document_root, port)

      sighandler = Proc.new { |signal| server.shutdown }
      SmallCage::Application.add_signal_handler(%w{INT TERM}, sighandler)

      server.start
    end
  end
end
