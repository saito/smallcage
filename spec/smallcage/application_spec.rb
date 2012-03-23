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

  it "should exit 1 if command is empty" do
    status = nil
    tmpout = StringIO.new
    begin
      original_out, $stdout = $stdout, tmpout
      @target.parse_options([])
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = original_out
    end
    status.should == 1
    tmpout.string.should =~ /\AUsage:/
    tmpout.string.should =~ /^Subcommands are:/
  end

  it "should show help" do
    status = nil
    tmpout = StringIO.new
    begin
      original_out, $stdout = $stdout, tmpout
      @target.parse_options(["help"])
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = original_out
    end
    status.should == 0
    tmpout.string.should =~ /\AUsage:/
    tmpout.string.should =~ /^Subcommands are:/
  end


  it "should show help if the arguments include --help" do
    status = nil
    tmpout = StringIO.new
    begin
      original_out, $stdout = $stdout, tmpout
      @target.parse_options(["--help", "update"])
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = original_out
    end
    status.should == 0
    tmpout.string.should =~ /\AUsage:/
    tmpout.string.should =~ /^Subcommands are:/
  end


  it "should show subcommand help" do
    status = nil
    tmpout = StringIO.new
    begin
      original_out, $stdout = $stdout, tmpout
      @target.parse_options(["help", "update"])
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = original_out
    end
    status.should == 0
    tmpout.string.should =~ /\AUsage: smc update \[path\]/
  end

  it "should exit if the command is unknown" do
    status = nil
    tmpout = StringIO.new
    tmperr = StringIO.new
    begin
      original_out, $stdout = $stdout, tmpout
      original_err, $stderr = $stderr, tmperr
      @target.parse_options(["xxxx"])
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = original_out
    end
    status.should == 1
    tmpout.string.should be_empty
    tmperr.string.should == "no such subcommand: xxxx\n"
  end


  it "should show version" do
    status = nil
    tmpout = StringIO.new
    tmperr = StringIO.new
    begin
      original_out, $stdout = $stdout, tmpout
      original_err, $stderr = $stderr, tmperr
      @target.parse_options(["--version", "update"])
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = original_out
    end
    status.should == 0
    tmpout.string.should =~ /\ASmallCage \d+\.\d+\.\d+ - /
    tmperr.string.should be_empty
  end

end
