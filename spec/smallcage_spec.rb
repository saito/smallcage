require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe "smallcage" do

  docroot = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")

  it "show version" do
    # puts "------- version:" + SmallCage::VERSION::STRING
  end
  
  it "should update not docroot directory" do
    path = docroot + "a/b/"

    opts = { :command => "update", :path => path.to_s, :quiet => true }
    
    begin
      SmallCage::Runner.run(opts)
    
      out = docroot + "a/b/c/index.html"
      out.file?.should be_true
      out.delete
    
      pwd = Dir.pwd
      Dir.chdir(path)
    
      opts[:path] = "."
      SmallCage::Runner.run(opts)
    
      Dir.chdir(pwd)

      out.file?.should be_true
      out.delete
    ensure
      SmallCage::Runner.run({:command => "clean", :path => path.to_s, :quiet => true })
    end
      
  end

end