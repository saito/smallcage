
namespace :cache do

  task :update do
    require "rexml/document" 
    list = FileList["**/*--latest.{css,js,png,gif,jpg}"]
    
    list.each do |path|
      src = %x{svn info --xml #{path}}
      begin
        doc = REXML::Document.new(src)
        revision = doc.elements['/info/entry/commit/@revision'].value
      rescue
        puts "Can't get revision number: #{path}"
      end
      to = path.pathmap("%{--latest$,-#{revision}}X%x")
      if File.exist?(to)
        puts "  SKIP(exists): #{path} -> #{to}"
        next
      else
        puts "  COPY: #{path} -> #{to}"
      end
      unless ENV["DRYRUN"]
        next if File.exist?(to)
        begin
          FileUtils.copy(path,to)
        rescue => e
          puts "  ERROR: #{e} #{path} -> #{to}"
        end
      end
    end
  end

end