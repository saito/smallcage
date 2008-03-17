require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe "SmallCage::Commands::Export" do

  docroot = Pathname.new(File.dirname(__FILE__) + "/data/htdocs2")
  outdir = Pathname.new(File.dirname(__FILE__) + "/data/out")
  
  it "should export not smc files" do
    begin
      opts = { :command => "export", 
               :path => docroot.to_s,
               :out => outdir.to_s,
               :quiet => true }
      SmallCage::Runner.run(opts)
    
      (outdir + "./a/test.html.smc").exist?.should_not be_true
      (outdir + "./a/test.html").exist?.should_not be_true
      (outdir + "./a/b/test.html").exist?.should be_true
      (outdir + "./a/b/c/test.html").exist?.should be_true
    ensure
      FileUtils.rm_r(outdir)
    end
  end
  
  it "should export project subdirectory" do
    begin
      path = docroot + "a/b/c"
      opts = { :command => "export", 
               :path => path.to_s,
               :out => outdir.to_s,
               :quiet => true }
      SmallCage::Runner.run(opts)
    
      (outdir + "./a/test.html.smc").exist?.should_not be_true
      (outdir + "./a/test.html").exist?.should_not be_true
      (outdir + "./a/b/test.html").exist?.should_not be_true
      
      (outdir + "./a/b/c/test.html").exist?.should be_true
    ensure
      FileUtils.rm_r(outdir)
    end
  end
  
end