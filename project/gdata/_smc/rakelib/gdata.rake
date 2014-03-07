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
    end
    @config ||= {}
    @config["gdata_auth"] ||= "default"
  end
  private :load_config

  def auth_file
    return AUTH_ROOT + "gdata_auth_#{@config["gdata_auth"]}.yml"
  end
  private :auth_file

  def umask_close
    old = File.umask
    File.umask(077)
    begin
      yield
    ensure
      File.umask(old)
    end
  end
  private :umask_close

  def config_sample
    puts <<'EOT'

Configulation sample (add these lines to _dir.smc):
----------------------------------------------------------------
gdata_auth: default
gdata_files:
- key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  file: _smc/data/sample1.csv
- key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  file: _smc/data/sample2.csv
----------------------------------------------------------------
You can get document keys using 'gdata:list' task.

EOT
  end
  private :config_sample

  def env
    unless File.file?(CONFIG_FILE)
      puts "ERROR: Configuration file not found: #{CONFIG_FILE}"
      config_sample
      return
    end
    puts "OK: Configuration file exists: #{CONFIG_FILE.realpath}"

    puts "OK: Auth name(gdata_auth): #{@config["gdata_auth"]}"

    if @config["gdata_files"]
      puts "OK: Configuration value exists: gdata_files"
      @config["gdata_files"].to_a.each do |fileconf|
        puts <<"EOT"
- title: "#{fileconf["title"]}"
  key: #{fileconf["key"]}
  file: #{fileconf["file"]}
EOT
      end
    else
      puts "ERROR: Counfiguration value not found: gdata_files"
      config_sample
    end

    unless AUTH_ROOT.exist?
      umask_close do
        Dir.mkdir(AUTH_ROOT)
        puts "OK: auth dir created: #{AUTH_ROOT}"
      end
    end
    if AUTH_ROOT.stat.mode & 077 != 0
      puts "ERROR: Close group/other permission for security: #{AUTH_ROOT}"
    end

    afile = auth_file
    if afile.file?
      if afile.stat.mode & 077 != 0
        puts "ERROR: Close group/other permission for security: #{afile}"
      else
        puts "OK: auth file exists: #{afile}"
      end
    else
      puts "ERROR: auth file doesn't exist. execute gdata:login task.: #{afile}"
    end
  end

  def login
    umask_close { _login }
  end

  def _login
    unless AUTH_ROOT.directory?
      Dir.mkdir(AUTH_ROOT)
      puts "OK: auth dir created: #{AUTH_ROOT}"
    end
    check_permission(AUTH_ROOT)

    if auth_file.exist?
      auth = YAML.load_file(auth_file)
    end
    auth ||= {}
    if auth["email"] || auth["pass"]
      puts "ERROR: using email/pass in the auth file: #{auth_file}"
      return
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
  private :_login

  def login_prompt_highline
    email = ask("Email: ")
    pass  = ask("Password: ") { |q| q.echo = '*' }
    return [email, pass]
  end
  private :login_prompt_highline

  def check_permission(path)
    if path.stat.mode & 077 != 0
      raise "Close group/other permission for security: #{path}"
    end
  end

  def list
    check_permission(auth_file.parent)
    check_permission(auth_file)

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
    check_permission(auth_file.parent)
    check_permission(auth_file)

    c = GData::Client::Spreadsheets.new
    auth = YAML.load_file(auth_file) || {}

    if auth["email"].to_s.empty?
      if auth["spreadsheets"].to_s.empty?
        puts "ERROR: execute gdata:login task."
        return
      end
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

  desc "Show Google Data API configuration."
  task :env do
    exporter = GDataExporter.new
    exporter.env
  end

  desc "Login Google Data API."
  task :login do
    exporter = GDataExporter.new
    exporter.login
  end

  desc "List all Google Spreadsheets."
  task :list do
    exporter = GDataExporter.new
    exporter.list
  end

  desc "Export Google Spreadsheets as CSV."
  task :export do
    exporter = GDataExporter.new
    exporter.export
  end
end