require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe 'update' do

  it "should update not docroot directory" do
    docroot  = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")
    path = docroot + "a/b/"

    opts = { :command => "update", :path => path.to_s, :quiet => true }
    
    begin
      SmallCage::Runner.run(opts)
    
      out = docroot + "a/b/c/index.html"
      out.file?.should be_true
      out.delete
    
      Dir.chdir(path) do
        opts[:path] = "."
        SmallCage::Runner.run(opts)
      end

      out.file?.should be_true
      out.delete
    ensure
      SmallCage::Runner.run({:command => "clean", :path => path.to_s, :quiet => true })
    end
      
  end
  
  it "should not publish _dir.smc and _local.smc" do
    root = Pathname.new(File.dirname(__FILE__) + "/data/htdocs3")

    opts = { :command => "update", :path => root.to_s, :quiet => true }
    
    begin
      SmallCage::Runner.run(opts)
    
      out = root + "_dir"
      out.file?.should be_false
    
      out = root + "_local"
      out.file?.should be_false
    ensure
      SmallCage::Runner.run({:command => "clean", :path => root.to_s, :quiet => true })
    end
    
  end
  
  # http://github.com/bluemark/smallcage/issues/#issue/2
  it "should not delete files under the common prefix directory" do
    root = Pathname.new(File.dirname(__FILE__) + "/data/htdocs3")
    begin
      SmallCage::Runner.run({ :command => "update", :path => root.to_s, :quiet => true })
      
      (root + "a/index.html").file?.should be_true
      (root + "ab/index.html").file?.should be_true
      (root + "abc/index.html").file?.should be_true

      SmallCage::Runner.run({ :command => "update", :path => (root + "a").to_s, :quiet => true })
      
      (root + "a/index.html").file?.should be_true
      (root + "ab/index.html").file?.should be_true
      (root + "abc/index.html").file?.should be_true

      SmallCage::Runner.run({ :command => "update", :path => (root + "ab").to_s, :quiet => true })

      (root + "a/index.html").file?.should be_true
      (root + "ab/index.html").file?.should be_true
      (root + "abc/index.html").file?.should be_true
    ensure
      SmallCage::Runner.run({:command => "clean", :path => root.to_s, :quiet => true })
    end
    
  end

  it "should cause error when undefined method called with argument." do
    root = Pathname.new(File.dirname(__FILE__) + "/data/htdocs4")
    begin
      lambda {
        SmallCage::Runner.run({:command => "update", :path => root.to_s, :quiet => true })
      }.should raise_error(NameError)

      begin
        SmallCage::Runner.run({:command => "update", :path => root.to_s, :quiet => true })
      rescue NameError => e
        msg = e.message
        msg.should match %r{^Can\'t render: /error1\.html: method_missing called with more than one argument: template:.+/_smc/templates/error1\.rhtml args:\[:abc, 123\]}
      end
    ensure
      SmallCage::Runner.run({:command => "clean", :path => root.to_s, :quiet => true })
    end
  end

  
end
