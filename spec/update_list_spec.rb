require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe SmallCage::UpdateList do
  root = Pathname.new(File.dirname(__FILE__) + "/data/updatelists")

  it "should create empty data" do
    data = SmallCage::UpdateList.new(root + "dummy.yml", "/")
  end

end
