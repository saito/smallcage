require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'
require 'pathname'

describe "smallcage" do

  docroot = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")

  it "show version" do
    # puts "------- version:" + SmallCage::VERSION::STRING
  end
  
  it "should load path value which returns Pathname object" do
    ldr = SmallCage::Loader.new(docroot)
    obj = ldr.load(docroot + "a/b/c/index.html.smc")

    obj["path"].should be_an_instance_of(Pathname)
    obj["path"].smc.should be_an_instance_of(Pathname)
    
    obj["path"].to_s.should =~ %r{^.+/a/b/c/index\.html$}
    obj["path"].smc.to_s.should =~ %r{^.+/a/b/c/index\.html\.smc$}
  end
  
  it "should be able to omit smc extention" do
    ldr = SmallCage::Loader.new(docroot + "a/b/c/index.html")
    objects = []
    ldr.each_smc_obj do |o|
      objects << o
    end
    objects.size.should == 1
    obj = objects[0]
    obj["uri"].should == "/a/b/c/index.html"
    obj["uri"].smc.should == "/a/b/c/index.html.smc"
  end
  
  it "should find smc root dir" do
    path = docroot + "a/b/c/index.html.smc"
    ldr = SmallCage::Loader.new(path)
    
    depth = 5
    root = ldr.find_root(path, depth)
    root.to_s.should =~ %r{^.+/data/htdocs1$}
    
    depth = 3
    lambda { ldr.find_root(path, depth) }.should raise_error
  end
  
  it "should update not docroot directory" do
    path = docroot + "a/b/"

    opts = { :command => "update", :path => path.to_s, :quiet => true }
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
  end

end