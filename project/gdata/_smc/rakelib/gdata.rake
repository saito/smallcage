require "rubygems"
require "gdata"
require "yaml"
require "highline/import"

class GDataExporter
  CONFIG_FILE = Pathname.new(File.dirname(__FILE__)).realpath + "../../_dir.smc"
  AUTH_ROOT   = Pathname.new(File.expand_path("~/.smallcage"))

  def initialize
    load_config
  end

  def load_config
    if File.file?(CONFIG_FILE)
      @config = YAML.load_file(CONFIG_FILE)
    else
      @config ||= {}
    end
    @config["gdata_auth"] ||= "default"
  end
  private :load_config

  def auth_file
    return AUTH_ROOT + "gdata_auth_#{@config["gdata_auth"]}.yml"
  end
  private :auth_file

  def env
    unless File.file?(CONFIG_FILE)
      puts "ERROR: Config file not found: #{CONFIG_FILE}"
      return
    end
    puts "OK: Config file exists: #{CONFIG_FILE.realpath}"

    puts "OK: Auth name(gdata_auth): #{@config["gdata_auth"]}"

    if @config["gdata_files"]
      puts "OK: gdata_files"
      @config["gdata_files"].to_a.each do |fileconf|
        puts <<"EOT"
- title: "#{fileconf["title"]}"
  key: #{fileconf["key"]}
  file: #{fileconf["file"]}
EOT
      end
    else
      puts <<'EOT'
ERROR: gdata_files doesn't set.

Configulation sample (add these lines to _dir.smc):
----------------------------------------------------------------
gdata_auth: default
gdata_files: 
- key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  file: _smc/data/sample1.csv
- key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  file: _smc/data/sample2.csv
----------------------------------------------------------------
You can get document keys using 'gdata:keys' task.

EOT
    end

    unless AUTH_ROOT.directory?
      puts "ERROR: #{AUTH_ROOT}/ doesn't exist. Create directory."
      return
    end
    if auth_file.exist?
      puts "OK: auth file exists: #{auth_file}"
    else
      puts "ERROR: auth file doesn't exist: #{auth_file}"
    end
  end
  
  def login
    auth = YAML.load_file(auth_file)
    auth ||= {}
    if auth["email"] || auth["pass"]
      puts "ERROR: using email/pass in the auth file: #{auth_file}"
    end

    (email,pass) = login_prompt_highline
    c = GData::Client::DocList.new
    auth["doclist"]      = c.clientlogin(email, pass)
    c = GData::Client::Spreadsheets.new
    auth["spreadsheets"] = c.clientlogin(email, pass)
    
    open(auth_file, "w") do |io|
      io << auth.to_yaml
    end
    puts "OK: Login token saved: #{auth_file}"
  end

  def login_prompt_highline
    email = ask("Email: ")
    pass  = ask("Password: ") { |q| q.echo = '*' }
    return [email, pass]
  end
  private :login_prompt_highline

  def list
    c = GData::Client::DocList.new
    auth = YAML.load_file(auth_file)

    if auth["email"].to_s.empty?
      c.auth_handler = GData::Auth::ClientLogin.new("writely")
      c.auth_handler.token = auth["doclist"]
    else
      c.clientlogin(auth["email"], auth["pass"])
    end

    xml = c.get("http://docs.google.com/feeds/documents/private/full/-/spreadsheet").to_xml
    xml.elements.each("entry") do |e|
      key = e.elements["gd:resourceId"].text.to_s.split(/:/)[1]
      title =  e.elements["title"].text
      puts <<"EOT"
- title: "#{title}"
  key: #{key}
  file: _smc/data/sample.csv

EOT
    end
  end

  def export
    c = GData::Client::Spreadsheets.new
    auth = YAML.load_file(auth_file)

    if auth["email"].to_s.empty?
      c.auth_handler = GData::Auth::ClientLogin.new("wise")
      c.auth_handler.token = auth["spreadsheets"]
    else
      c.clientlogin(auth["email"], auth["pass"])
    end

    @config["gdata_files"].each do |fdata|
      next if fdata["key"] =~ /^x{44}$/
      data = c.get("http://spreadsheets.google.com/feeds/download/spreadsheets/Export?key=#{fdata["key"]}&exportFormat=csv")
      contents = data.body
      open(File.dirname(__FILE__) + "/../../" + fdata["file"], "w") do |io|
        io << contents
      end
    end
  end
end

namespace :gdata do

  task :env do
    exporter = GDataExporter.new
    exporter.env
  end

  desc "login Google Data API."
  task :login do
    exporter = GDataExporter.new
    exporter.login
  end

  task :list do
    exporter = GDataExporter.new
    exporter.list
  end

  task :update do
    exporter = GDataExporter.new
    exporter.export
  end


end