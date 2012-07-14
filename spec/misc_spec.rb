require 'spec_helper.rb'
require 'smallcage'

describe "misc" do

  it "should camelize String" do
    s = "smallcage"
    s.camelize.should == "Smallcage"

    s = "abc_def_ghi"
    s.camelize.should == "AbcDefGhi"
    
    s = ""
    s.camelize.should == ""
  end
  
  it "should camelize with first character in lower case" do
    s = "smallcage"
    s.camelize(false).should == "smallcage"
    
    s = "abc_def_ghi"
    s.camelize(false).should == "abcDefGhi"
  end

end
