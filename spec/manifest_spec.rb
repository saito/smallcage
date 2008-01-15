require File.dirname(__FILE__) + '/spec_helper.rb'
require 'smallcage'

describe "SmallCage::Commands::Manifest" do
  docroot = Pathname.new(File.dirname(__FILE__) + "/data/htdocs1")

  it "should create Manifest.html" do
    opts = { :command => "manifest", :path => docroot.to_s }
    SmallCage::Runner.run(opts)
    
    manifest = docroot + "Manifest.html"
    manifest.file?.should be_true
    
    source = manifest.read
    source.include?(<<'EOT').should be_true
<ul class="files">
<li><a href="./a/">./a/</a></li>
<li><a href="./a/b/">./a/b/</a></li>
<li><a href="./a/b/c/">./a/b/c/</a></li>
<li><a href="./a/b/c/index.html.smc">./a/b/c/index.html.smc</a></li>
<li><a href="./_dir.smc">./_dir.smc</a></li>
<li><a href="./_smc/">./_smc/</a></li>
<li><a href="./_smc/helpers/">./_smc/helpers/</a></li>
<li><a href="./_smc/templates/">./_smc/templates/</a></li>
</ul>
EOT

    manifest.delete
    manifest.file?.should be_false
  end

end