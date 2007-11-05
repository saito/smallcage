require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'
require 'pathname'

describe "smallcage" do

  docroot = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")

  it "show version" do
    # puts "------- version:" + SmallCage::VERSION::STRING
  end
  
  it "should load path value which returns Pathname object" do
    d = SmallCage::Loader.new(docroot)
    obj = d.load(docroot + "a/b/c/index.html.smc")

    obj["path"].should be_an_instance_of(Pathname)
    obj["path"].smc.should be_an_instance_of(Pathname)
    
    obj["path"].to_s.should =~ %r{^.+/a/b/c/index\.html$}
    obj["path"].smc.to_s.should =~ %r{^.+/a/b/c/index\.html\.smc$}
  end

end