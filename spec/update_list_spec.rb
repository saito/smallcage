require 'spec_helper.rb'
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
    result["version"].should match(/^\d\.\d\.\d$/)
    result["list"].should be_empty
  end

  it "should be update list items" do
    list = SmallCage::UpdateList.new(root + "dummy.yml", "/")
    result = YAML.load(list.to_yaml)
    list.update("/abc/index.html.smc", 100, "/abc/index.html")
  end

  it "should update version" do
    file = root + "list-version.yml"
    begin
      open(file, "w") do |io|
        io << <<EOT
version: 0.0.0
EOT
      end
      list = SmallCage::UpdateList.new(file, "/")
      list.save

      data = YAML.load_file(file)
      data["version"].should == SmallCage::VERSION
    ensure
      file.delete
    end
  end

  it "should save mtime" do
    file = root + "list-mtime.yml"
    begin
      list = SmallCage::UpdateList.new(file, "/")
      list.update("/index.html.smc", 1234567890, "/index.html")
      list.save
      
      list = SmallCage::UpdateList.new(file, "/")
      list.mtime("/index.html.smc").should == 1234567890

      # same dst file
      list.update("/abc/index.html.smc", 1, "/index.html")
      list.mtime("/abc/index.html.smc").should == 1

      list.update("/abc/index.html.smc", 2, "/index.html")
      list.mtime("/abc/index.html.smc").should == 2
      list.mtime("/index.html.smc").should == 1234567890

      list = SmallCage::UpdateList.new(file, "/")
      list.mtime("/index.html.smc").should == 1234567890
      list.mtime("/abc/index.html.smc").should == -1

      list.update("/abc/index.html.smc", 1, "/index.html")
      list.save

      list = SmallCage::UpdateList.new(file, "/")
      list.mtime("/index.html.smc").should == 1234567890
      list.mtime("/abc/index.html.smc").should == 1
    ensure
      file.delete
    end
  end

  it "should return expired files" do
    file = root + "list-expire.yml"
    begin
      list = SmallCage::UpdateList.new(file, "/")
      list.update("/index.html.smc", 1, "/index.html")

      e = list.expire
      e.length.should == 0

      list.save
      list.update_count.should == 1

      list = SmallCage::UpdateList.new(file, "/")
      e = list.expire
      e.length.should == 1
      e[0].should == "/index.html"
      list.update_count.should == 0

      list = SmallCage::UpdateList.new(file, "/")
      list.update("/index.html.smc", 1, "/index.html")
      e = list.expire
      e.length.should == 0
      list.update_count.should == 1

      list = SmallCage::UpdateList.new(file, "/")
      list.update("/index.html.smc", 1, "/index.html")
      list.update("/index.html.smc", 1, "/index2.html")
      e = list.expire
      e.length.should == 0
      list.update_count.should == 2
      list.save

      list = SmallCage::UpdateList.new(file, "/")
      e = list.expire
      e.length.should == 2
      e.should =~ ["/index.html", "/index2.html"]

      list = SmallCage::UpdateList.new(file, "/abc/")
      list.update("/abc/index.html.smc", 2, "/abc/index.html")
      list.update("/abc/index2.html.smc", 3, "/abc/index2.html")
      e = list.expire
      e.length.should == 0
      list.update_count.should == 2
      list.save

      list = SmallCage::UpdateList.new(file, "/abc/")
      list.update("/abc/index.html.smc", 2, "/abc/index2.html")
      e = list.expire
      e.length.should == 1
      e[0].should == "/abc/index.html"

      list = SmallCage::UpdateList.new(file, "/a/")
      list.update("/a/index.html.smc", 2, "/abc/a.html")
      e = list.expire
      e.length.should == 0
      list.update_count.should == 1
      list.save

      list = SmallCage::UpdateList.new(file, "/abc/")
      list.update("/abc/index.html.smc", 2, "/abc/index.html")
      list.update("/abc/index.html.smc", 2, "/abc/index2.html")
      e = list.expire
      e.length.should == 0
      list.update_count.should == 2
      list.save

      list = SmallCage::UpdateList.new(file, "/a/")
      list.update("/a/index.html.smc", 2, "/abc/b.html")
      e = list.expire
      e.length.should == 1
      e[0] == "/abc/a.html"

      list = SmallCage::UpdateList.new(file, "/")
      e = list.expire
      e.length.should == 5
      e.should include("/index.html")
      e.should include("/index2.html")
      e.should include("/abc/index.html")
      e.should include("/abc/index2.html")
      e.should include("/abc/a.html")
      list.save

      list = SmallCage::UpdateList.new(file, "/")
      e = list.expire
      e.length.should == 0
    ensure
      file.delete
    end
  end

  it "should support single file target" do
    file = root + "list-single.yml"
    begin
      list = SmallCage::UpdateList.new(file, "/index.html.smc")
      list.update("/index.html.smc", 1, "/index.html")
      e = list.expire
      e.length.should == 0
      list.save

      list = SmallCage::UpdateList.new(file, "/index.html.smc")
      e = list.expire
      e.length.should == 1

      list = SmallCage::UpdateList.new(file, "/index2.html.smc")
      e = list.expire
      e.length.should == 0

      list = SmallCage::UpdateList.new(file, "/index.html.smc/")
      e = list.expire
      e.length.should == 0

      list = SmallCage::UpdateList.new(file, "/abc/index.html.smc")
      list.update("/abc/index.html.smc", 2, "/abc/index.html")
      e = list.expire
      e.length.should == 0
      list.save
      list = SmallCage::UpdateList.new(file, "/ab/")
      e = list.expire
      e.length.should == 0

      list = SmallCage::UpdateList.new(file, "/")
      e = list.expire
      e.length.should == 2
    ensure
      file.delete
    end
  end

  it "should not expire file which other source published" do
    file = root + "list-switch.yml"
    begin
      list = SmallCage::UpdateList.new(file, "/")
      list.update("/index.html.smc", 1, "/aaa")
      list.update("/index.html.smc", 1, "/bbb")
      e = list.expire
      e.length.should == 0
      list.save

      list = SmallCage::UpdateList.new(file, "/")
      e = list.expire
      e.length.should == 2

      list = SmallCage::UpdateList.new(file, "/")
      list.update("/other/file/1.smc", 2, "/aaa")
      list.update("/other-file-2.smc", 2, "/bbb")
      e = list.expire
      e.length.should == 0
    ensure
      file.delete
    end
  end
end
