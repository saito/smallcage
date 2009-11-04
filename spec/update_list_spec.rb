require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe SmallCage::UpdateList do
  root = Pathname.new(File.dirname(__FILE__) + "/data/updatelists")

  it "should create empty data" do
    list = SmallCage::UpdateList.new(root + "dummy.yml", "/")
    result = YAML.load(list.to_yaml)
    result["version"].should match(/\d\.\d\.\d/)
    result["list"].should be_empty

    list = SmallCage::UpdateList.new(root + "dummy.yml", "/")
    list.expire
    result = YAML.load(list.to_yaml)
    result["version"].should match(/\d\.\d\.\d/)
    result["list"].should be_empty
  end

  it "should be update list items" do
    list = SmallCage::UpdateList.new(root + "dummy.yml", "/")
    result = YAML.load(list.to_yaml)
    list.update("/abc/index.html.smc", 100, "/abc/index.html")
  end

end
