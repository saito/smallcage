require 'spec_helper.rb'
require 'smallcage'
require 'smallcage/commands/manifest'

describe SmallCage::Commands::Manifest do

  before do
    @docroot = Pathname.new(File.join(SPEC_DATA_DIR, 'htdocs1'))
    @opts = { :path => @docroot.to_s }
    @manifest_file = @docroot + "Manifest.html"
  end

  it "should create Manifest.html" do

    SmallCage::Runner.run(@opts.merge(:command => "manifest"))
    @manifest_file.file?.should be_true

    source = @manifest_file.read
    source = source.match(%r{<ul class="files">\n(.+?)\n</ul>}m)[1].split(/\n/)

    contents = <<'EOT'.split(/\n/)
<li><a href="./_dir.smc">./_dir.smc</a></li>
<li><a href="./_smc/">./_smc/</a></li>
<li><a href="./_smc/filters/">./_smc/filters/</a></li>
<li><a href="./_smc/filters/filters.yml">./_smc/filters/filters.yml</a></li>
<li><a href="./a/">./a/</a></li>
<li><a href="./a/b/">./a/b/</a></li>
<li><a href="./a/b/c/">./a/b/c/</a></li>
<li><a href="./a/b/c/index.html.smc">./a/b/c/index.html.smc</a></li>
EOT

    source.each do |line|
      contents.should include(line)
    end
  end

  after do
    SmallCage::Runner.run(@opts.merge(:command => "clean", :quiet => true))
    @manifest_file.delete
  end

end
