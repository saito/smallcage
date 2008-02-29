require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe "SmallCage::DocumentPath" do
  root = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")
  
  before do
    @docpath = SmallCage::DocumentPath.new(root, root + "a/b/c/index.html.smc")
  end
  
  it "should have uri property" do
    @docpath.uri.should == "/a/b/c/index.html.smc"
  end
  
  it "should tell smc file or not" do
    @docpath.smc?.should be_true
  end
  
  it "should have outfile method" do
    out = @docpath.outfile
    out.should be_an_instance_of(SmallCage::DocumentPath)
    out.path.basename.to_s.should == "index.html"
    out.path.to_s.should match(%r{^/.+/a/b/c/index.html$})
    @docpath.path.to_s[0..-5].should == out.path.to_s
  end
  
  it "should have outuri method" do
    out = @docpath.outuri
    out.should == "/a/b/c/index.html"
  end
end