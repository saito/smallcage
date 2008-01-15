require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'
require 'pathname'

describe "smallcage" do

  it "should camelize String" do
    s = "smallcage"
    s.camelize.should == "Smallcage"

    s = "abc_def_ghi"
    s.camelize.should == "AbcDefGhi"
    
    s = ""
    s.camelize.should == ""
  end
  
  it "camelize with lower case first character" do
    s = "smallcage"
    s.camelize(false).should == "smallcage"
    
    s = "abc_def_ghi"
    s.camelize(false).should == "abcDefGhi"
  end

end