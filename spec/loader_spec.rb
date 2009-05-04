require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe SmallCage::Loader do

  before do
    @docroot = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")
  end

  it "should load path value which is instance of Pathname" do
    ldr = SmallCage::Loader.new(@docroot)
    obj = ldr.load(@docroot + "a/b/c/index.html.smc")

    obj["path"].should be_an_instance_of(Pathname)
    obj["path"].smc.should be_an_instance_of(Pathname)
    
    obj["path"].to_s.should =~ %r{^.+/a/b/c/index\.html$}
    obj["path"].smc.to_s.should =~ %r{^.+/a/b/c/index\.html\.smc$}
  end
  
  it "should be able to omit smc extention" do
    ldr = SmallCage::Loader.new(@docroot + "a/b/c/index.html")
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
    path = @docroot + "a/b/c/index.html.smc"
    
    depth = 5
    root = SmallCage::Loader.find_root(path, depth)
    root.to_s.should =~ %r{^.+/data/htdocs1$}
    
    depth = 3
    lambda { SmallCage::Loader.find_root(path, depth) }.should raise_error
  end
  
  it "should load strings" do
    path = @docroot + "a/b/c/index.html.smc"
    ldr = SmallCage::Loader.new(path)

    root = SmallCage::Loader.find_root(path)
    objects = []
    ldr.each_smc_obj do |o|
      objects << o
    end
    objects[0]["strings"][0].should == "abc\ndef\n\nghi"
  end
  
  it "should load body value which equals strings[0]" do
    ldr = SmallCage::Loader.new(@docroot)
    obj = ldr.load(@docroot + "a/b/c/index.html.smc")
    
    obj["strings"][0].should == "abc\ndef\n\nghi"  
    obj["body"].should == obj["strings"][0]
    
    # same String instance
    obj["strings"][0].replace("XXX")
    obj["body"].should == "XXX"

    obj["strings"][0] = "ABC"
    obj["body"].should == "XXX"
  end
  
  it "should load dirs" do
    ldr = SmallCage::Loader.new(@docroot)
    obj = ldr.load(@docroot + "a/b/c/index.html.smc")
    
    dirs = obj["dirs"]
    dirs.length.should == 4
    
    dirs[0]["uri"].should == "/"
    dirs[1]["uri"].should == "/a/"
    dirs[2]["uri"].should == "/a/b/"
    dirs[3]["uri"].should == "/a/b/c/"
    (dirs[3]["path"] + "index.html.smc").file?.should be_true
    
    dirs[0]["var"].should == "xxx"
    dirs[0]["strings"][0].should == "BODYBODYBODY"
    dirs[0]["body"].should == "BODYBODYBODY"
  end
  
end