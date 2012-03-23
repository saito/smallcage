require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'smallcage'

describe SmallCage::Application do

  def capture_result
    status = nil
    result = nil
    tmpout = StringIO.new
    tmperr = StringIO.new
    original_out, $stdout = $stdout, tmpout
    original_err, $stderr = $stderr, tmperr
    begin
      result = yield
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = original_out
      $stderr = original_err
    end

    return { 
      :exit => status,
      :result => result,
      :stdout => tmpout.string,
      :stderr => tmperr.string
    }
  end

  before(:each) do
    @target = SmallCage::Application.new
  end

  it "should parse update command" do
    options = @target.parse_options(["update", "."])
    options.should == { :path => ".", :command => :update, :quiet => false }

    options = @target.parse_options(["up", "."])
    options.should == { :path => ".", :command => :update, :quiet => false }
  end

  it "should parse clean command" do
    options = @target.parse_options(["clean", "."])
    options.should == { :path => ".", :command => :clean, :quiet => false }
  end

  it "should parse server command" do
    options = @target.parse_options(["server", "."])
    options.should == { :path => ".", :command => :server, :quiet => false, :port => 8080 } # num

    options = @target.parse_options(["sv", ".", "8080"])
    options.should == { :path => ".", :command => :server, :quiet => false, :port => 8080 } # string
  end

  it "should accept only number port" do
    result = capture_result { @target.parse_options(["server", ".", "pot"]) }
    result[:exit].should == 1
    result[:stdout].should be_empty
    result[:stderr].should == "illegal port number: pot\n"
  end

  it "should not accept port 0" do
    result = capture_result { @target.parse_options(["server", ".", "0"]) }
    result[:exit].should == 1
    result[:stdout].should be_empty
    result[:stderr].should == "illegal port number: 0\n"
  end

  it "should parse auto command" do
    options = @target.parse_options(["auto", "."])
    options.should == { :path => ".", :command => :auto, :port => nil, :bell => false, :quiet => false }

    options = @target.parse_options(["au", ".", "8080"])
    options.should == { :path => ".", :command => :auto, :port => 8080, :bell => false, :quiet => false }
  end

  it "should parse import command" do
    options = @target.parse_options(["import", "base", "."])
    options.should == {  :command => :import, :from => "base", :to => ".", :quiet => false }

    options = @target.parse_options(["import"])
    options.should == {  :command => :import, :from => "default", :to => ".", :quiet => false }
  end
  
  it "should parse export command" do
    options = @target.parse_options(["export", ".", "path"])
    options.should == { :command => :export, :path => ".",  :out => "path", :quiet => false }

    options = @target.parse_options(["export"])
    options.should == { :command => :export, :path => ".",  :out => nil, :quiet => false }
  end

  it "should parse uri command" do
    options = @target.parse_options(["uri", "./path/to/target"])
    options.should == { :command => :uri, :path => "./path/to/target", :quiet => false }

    options = @target.parse_options(["uri"])
    options.should == { :command => :uri, :path => ".", :quiet => false }
  end

  it "should parse manifest command" do
    options = @target.parse_options(["manifest", "./path/to/target"])
    options.should == { :command => :manifest, :path => "./path/to/target", :quiet => false }

    options = @target.parse_options(["manifest"])
    options.should == { :command => :manifest, :path => ".", :quiet => false }
  end

  it "should exit 1 if command is empty" do
    result = capture_result { @target.parse_options([]) }
    result[:exit].should == 1
    result[:stdout].should =~ /\AUsage:/
    result[:stdout].should =~ /^Subcommands are:/
    result[:stderr].should be_empty
  end

  it "should show help" do
    result = capture_result { @target.parse_options(["help"]) }
    result[:exit].should == 0
    result[:stdout].should =~ /\AUsage:/
    result[:stdout].should =~ /^Subcommands are:/
    result[:stderr].should be_empty
  end

  it "should show help if the arguments include --help" do
    result = capture_result { @target.parse_options(["--help", "update"]) }
    result[:exit].should == 0
    result[:stdout].should =~ /\AUsage:/
    result[:stdout].should =~ /^Subcommands are:/
    result[:stderr].should be_empty
  end

  it "should show subcommand help" do
    result = capture_result { @target.parse_options(["help", "update"]) }
    result[:exit].should == 0
    result[:stdout].should =~ /\AUsage: smc update \[path\]/
    result[:stderr].should be_empty
  end

  it "should exit if the command is unknown" do
    result = capture_result { @target.parse_options(["xxxx"]) }
    result[:exit].should == 1
    result[:stdout].should be_empty
    result[:stderr].should == "no such subcommand: xxxx\n"
  end

  it "should show version" do
    result = capture_result { @target.parse_options(["--version", "update"]) }
    result[:exit].should == 0
    result[:stdout].should =~ /\ASmallCage \d+\.\d+\.\d+ - /
    result[:stderr].should be_empty
  end

  it "should exit when subcommand is empty" do
    result = capture_result { @target.parse_options(["", "--version"]) }
    result[:exit].should == 1
    result[:stdout].should =~ /\AUsage:/
    result[:stdout].should =~ /^Subcommands are:/
    result[:stderr].should be_empty
  end

  it "should ignore subcommand with --version option" do
    result = capture_result { @target.parse_options(["help", "--version"]) }
    result[:exit].should == 0
    result[:stdout].should =~ /\ASmallCage \d+\.\d+\.\d+ - /
    result[:stderr].should be_empty
  end

  it "should ignore subcommand with -v option" do
    result = capture_result { @target.parse_options(["help", "-v"]) }
    result[:exit].should == 0
    result[:stdout].should =~ /\ASmallCage \d+\.\d+\.\d+ - /
    result[:stderr].should be_empty
  end

  it "should ignore subcommand with --help option" do
    result = capture_result { @target.parse_options(["update", "--help"]) }
    result[:exit].should == 0
    result[:stdout].should =~ /\AUsage: smc update \[path\] \[options\]/
    result[:stderr].should be_empty
  end

  it "should ignore subcommand with -h option" do
    result = capture_result { @target.parse_options(["update", "-h"]) }
    result[:exit].should == 0
    result[:stdout].should =~ /\AUsage: smc update \[path\] \[options\]/
    result[:stderr].should be_empty
  end

  it "should exit with unknown main option --QQQ" do
    result = capture_result { @target.parse_options(["--QQQ"]) }
    result[:exit].should == 1
    result[:stdout].should be_empty
    result[:stderr].should == "invalid option: --QQQ\n"
  end

  it "should exit with unknown sub option --QQQ" do
    result = capture_result { @target.parse_options(["update", "--QQQ"]) }
    result[:exit].should == 1
    result[:stdout].should be_empty
    result[:stderr].should == "invalid option: --QQQ\n"
  end

  it "should accept auto command --bell option" do
    result = capture_result { @target.parse_options(["auto", "--bell"]) }
    result[:exit].should == nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should == {
      :command => :auto,
      :port => nil,
      :path => ".",
      :bell => true,
      :quiet => false,
    }
  end

  it "should set bell option false as default" do
    result = capture_result { @target.parse_options(["auto"]) }
    result[:exit].should == nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should == {
      :command => :auto,
      :port => nil,
      :path => ".",
      :bell => false,
      :quiet => false,
    }
  end

  it "should accept --quiet option" do
    result = capture_result { @target.parse_options(["--quiet", "update"]) }
    result[:exit].should == nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should == {
      :command => :update,
      :path => ".",
      :quiet => true,
    }
  end

  it "should accept --quiet option after subcommand" do
    result = capture_result { @target.parse_options(["update", "--quiet"]) }
    result[:exit].should == nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should == {
      :command => :update,
      :path => ".",
      :quiet => true,
    }
  end

  it "should accept --quiet option before and after subcommand" do
    opts = ["--quiet", "auto", "--quiet", "path", "--bell", "80"]
    result = capture_result { @target.parse_options(opts) }
    result[:exit].should == nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should == {
      :command => :auto,
      :path => "path",
      :port => 80,
      :bell => true,
      :quiet => true,
    }
  end

end
