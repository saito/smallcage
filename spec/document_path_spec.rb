require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe SmallCage::DocumentPath do
  
  before do
    @rootdir = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")
    @docpath = SmallCage::DocumentPath.new(@rootdir, @rootdir + "a/b/c/index.html.smc")
  end
  
  it "should have uri property" do
    @docpath.uri.should == "/a/b/c/index.html.smc"
  end
  
  it "should return smc file or not" do
    @docpath.smc?.should be_true
  end
  
  it "should return output file" do
    out = @docpath.outfile
    out.should be_an_instance_of(SmallCage::DocumentPath)
    out.path.basename.to_s.should == "index.html"
    out.path.to_s.should match(%r{^/.+/a/b/c/index.html$})
    @docpath.path.to_s[0..-5].should == out.path.to_s
  end
  
  it "should return output file uri" do
    out = @docpath.outuri
    out.should == "/a/b/c/index.html"
  end
  
  it "should return root uri" do
    docpath = SmallCage::DocumentPath.new(@rootdir, @rootdir)
    docpath.uri.should == "/"
  end
  
  it "should return directory uri" do
    docpath = SmallCage::DocumentPath.new(@rootdir, @rootdir + "a/b")
    docpath.uri.should == "/a/b"
  end

  it "should raise Exception when the path doesn't exist under the root directory" do
    rootdir = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")
    path    = Pathname.new(File.dirname(__FILE__))

    ok = false
    begin
      docpath = SmallCage::DocumentPath.new(rootdir, path)
    rescue => e
      e.message.should =~ /\AIllegal path: /
      ok = true
    end
    ok.should be_true


    rootdir = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")
    path    = Pathname.new(File.dirname(__FILE__) + "/data/htdocs")

    ok = false
    begin
      docpath = SmallCage::DocumentPath.new(rootdir, path)
    rescue => e
      e.message.should =~ /\AIllegal path: /
      ok = true
    end
    ok.should be_true


    rootdir = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")
    path    = Pathname.new(File.dirname(__FILE__) + "/data/htdocs2")

    ok = false
    begin
      docpath = SmallCage::DocumentPath.new(rootdir, path)
    rescue => e
      e.message.should =~ /\AIllegal path: /
      ok = true
    end
    ok.should be_true
  end
  
end
