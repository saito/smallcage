require 'webrick'

module SmallCage::Commands
  class Server
    def self.execute(opts)
      document_root = opts[:path]
      port = opts[:port]

      server = WEBrick::HTTPServer.new({
        :DocumentRoot => document_root,
        :BindAddress => '0.0.0.0',
        :Port => port
      })

      ['INT', 'TERM'].each do |signal|
        Signal.trap(signal){ server.shutdown }
      end
      server.start    
    end
  end
end