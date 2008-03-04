require 'webrick'

module SmallCage
  class HTTPServer
  
    def initialize(document_root, port)
      # logger = WEBrick::Log.new(nil, 1)
      @server = WEBrick::HTTPServer.new({
        :DocumentRoot => document_root,
        :Port => port,
        :AccessLog => [[File.open("/dev/null", "w+"), ""]]
      })

      WEBrick::HTTPServlet::FileHandler.remove_handler("cgi")
      WEBrick::HTTPServlet::FileHandler.remove_handler("rhtml")

      @server.mount("/_smc/update_uri", UpdateUriServlet)
      @server.mount("/_smc/auto", AutoServlet)
    end
    
    def start
      @server.start
    end
    
    def shutdown
      @server.shutdown
    end
    
    def updated_uri=(uri)
      UpdateUriServlet.uri = uri
    end

  end


  class UpdateUriServlet < WEBrick::HTTPServlet::AbstractServlet
    @@uri = "/index.html"
    @@update_time = ""
  
    def do_GET(req, res)
      res['content-type'] = "text/plain"
      res.body = @@uri + "\n" + @@update_time
    end
    
    def self.uri=(uri)
      @@uri = uri
      @@update_time = Time.now.to_s
    end
  end

  class AutoServlet < WEBrick::HTTPServlet::AbstractServlet
    def do_GET(req, res)
      res['content-type'] = "text/html"
      html = File.dirname(__FILE__) + "/auto.html"
      res.body = File.read(html)
    end
  end
end