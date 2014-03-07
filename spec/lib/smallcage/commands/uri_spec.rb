require 'spec_helper.rb'
require 'smallcage'
require 'smallcage/commands/uri'

describe SmallCage::Commands::Uri do
  it "should prints all uris" do
    path = Pathname.new(File.join(SPEC_DATA_DIR, 'multifiles'))

    old_stdout = $stdout
    begin
      $stdout = StringIO.new
      opts = { :command => "uri", :path => path.to_s }
      SmallCage::Runner.run(opts)
      $stdout.string.should == <<EOT
/index.html
/items/items-000.html
/items/items-001.html
/items/items-002.html
/items/items-003.html
/items/items-004.html

/items/items-after-emptyline.html
EOT
    ensure
      $stdout = old_stdout
    end
  end

  it "should prints partial uris" do
    path = Pathname.new(File.join(SPEC_DATA_DIR, 'multifiles'))

    old_stdout = $stdout
    begin
      $stdout = StringIO.new
      opts = { :command => "uri", :path => path.to_s + "/index.html.smc" }
      SmallCage::Runner.run(opts)
      $stdout.string.should == <<EOT
/index.html
EOT

      $stdout = StringIO.new
      opts = { :command => "uri", :path => path.to_s + "/items/index.html.smc"}
      SmallCage::Runner.run(opts)
      $stdout.string.should == <<EOT
/items/items-000.html
/items/items-001.html
/items/items-002.html
/items/items-003.html
/items/items-004.html

/items/items-after-emptyline.html
EOT
    ensure
      $stdout = old_stdout
    end
  end
end
