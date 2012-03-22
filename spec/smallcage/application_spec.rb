require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'smallcage'

describe SmallCage::Application do

  before(:each) do
    @target = SmallCage::Application.new
  end

  it "should parse update command" do
    options = @target.parse_options(["update", "."])
    options.should == { :path => ".", :command => :update }

    options = @target.parse_options(["up", "."])
    options.should == { :path => ".", :command => :update }
  end

  it "should parse clean command" do
    options = @target.parse_options(["clean", "."])
    options.should == { :path => ".", :command => :clean }
  end

  it "should parse server command" do
    options = @target.parse_options(["server", "."])
    options.should == { :path => ".", :command => :server, :port => 80 } # num

    options = @target.parse_options(["sv", ".", "8080"])
    options.should == { :path => ".", :command => :server, :port => "8080" } # string
  end

  it "should parse auto command" do
    options = @target.parse_options(["auto", "."])
    options.should == { :path => ".", :command => :auto, :port => nil }

    options = @target.parse_options(["au", ".", "8080"])
    options.should == { :path => ".", :command => :auto, :port => "8080" }
  end

  it "should parse import command" do
    options = @target.parse_options(["import", "base", "."])
    options.should == {  :command => :import, :from => "base", :to => "." }

    options = @target.parse_options(["import"])
    options.should == {  :command => :import, :from => "default", :to => "." }
  end
  
  it "should parse export command" do
    options = @target.parse_options(["export", ".", "path"])
    options.should == { :command => :export, :path => ".",  :out => "path" }

    options = @target.parse_options(["export"])
    options.should == { :command => :export, :path => ".",  :out => nil }
  end

  it "should parse uri command" do
    options = @target.parse_options(["uri", "./path/to/target"])
    options.should == { :command => :uri, :path => "./path/to/target" }

    options = @target.parse_options(["uri"])
    options.should == { :command => :uri, :path => "." }
  end

  it "should parse manifest command" do
    options = @target.parse_options(["manifest", "./path/to/target"])
    options.should == { :command => :manifest, :path => "./path/to/target" }

    options = @target.parse_options(["manifest"])
    options.should == { :command => :manifest, :path => "." }
  end


end
