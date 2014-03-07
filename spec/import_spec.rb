require 'spec_helper.rb'
require 'smallcage'

describe "SmallCage::Commands::Import" do
  root = Pathname.new(File.dirname(__FILE__) + "/data")

  it "should import default project" do
    tmpdir = root + "tmp"
    Dir.mkdir(tmpdir) unless tmpdir.directory?

    opts = { :command => "import", :from => "default", :to => tmpdir.to_s, :quiet => true }
    SmallCage::Runner.run(opts)

    (tmpdir + "_smc").directory?.should be_true
    (tmpdir + "_smc/helpers/base_helper.rb").file?.should be_true

    FileUtils.rm_r(tmpdir)
  end
end
