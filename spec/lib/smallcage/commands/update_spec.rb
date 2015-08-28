require 'spec_helper.rb'
require 'smallcage'
require 'smallcage/commands/update'

describe SmallCage::Commands::Update do

  it "should not update docroot directory" do
    docroot  = Pathname.new(File.join(SPEC_DATA_DIR, 'htdocs1'))
    path = docroot + "a/b/"

    opts = { :command => "update", :path => path.to_s, :quiet => true }

    begin
      SmallCage::Runner.run(opts)

      out = docroot + "a/b/c/index.html"
      out.file?.should be true
      out.delete

      Dir.chdir(path) do
        opts[:path] = "."
        SmallCage::Runner.run(opts)
      end

      out.file?.should be true
      out.delete
    ensure
      SmallCage::Runner.run({:command => "clean", :path => path.to_s, :quiet => true })
    end
  end

  it "should not publish _dir.smc and _local.smc" do
    root = Pathname.new(File.join(SPEC_DATA_DIR, 'htdocs3'))

    opts = { :command => "update", :path => root.to_s, :quiet => true }

    begin
      SmallCage::Runner.run(opts)

      out = root + "_dir"
      out.file?.should be false

      out = root + "_local"
      out.file?.should be false
    ensure
      SmallCage::Runner.run({:command => "clean", :path => root.to_s, :quiet => true })
    end
  end

  # http://github.com/bluemark/smallcage/issues/#issue/2
  it "should not delete files under the common prefix directory" do
    root = Pathname.new(File.join(SPEC_DATA_DIR, 'htdocs3'))
    begin
      SmallCage::Runner.run({ :command => "update", :path => root.to_s, :quiet => true })

      (root + "a/index.html").file?.should be true
      (root + "ab/index.html").file?.should be true
      (root + "abc/index.html").file?.should be true

      SmallCage::Runner.run({ :command => "update", :path => (root + "a").to_s, :quiet => true })

      (root + "a/index.html").file?.should be true
      (root + "ab/index.html").file?.should be true
      (root + "abc/index.html").file?.should be true

      SmallCage::Runner.run({ :command => "update", :path => (root + "ab").to_s, :quiet => true })

      (root + "a/index.html").file?.should be true
      (root + "ab/index.html").file?.should be true
      (root + "abc/index.html").file?.should be true
    ensure
      SmallCage::Runner.run({:command => "clean", :path => root.to_s, :quiet => true })
    end
  end
end
