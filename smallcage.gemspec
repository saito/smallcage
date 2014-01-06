# -*- encoding: utf-8 -*-
require File.expand_path('../lib/smallcage/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["SAITO Toshihiro", "gommmmmm", "KOSEKI Kengo"]
  gem.email         = ["smallcage@googlegroups.com"]
  gem.description   = %q{SmallCage is a simple, but powerful website generator. It converts content and template files, which has common elements in a website, to a plain, static website. No database, no application container, and no repeat in many pages is needed. You can keep your site well with very little work.}
  gem.summary       = %q{a simple website generator}
  gem.homepage      = %q{http://www.smallcage.org}

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "smallcage"
  gem.require_paths = ["lib"]
  gem.version       = SmallCage::VERSION
  gem.extensions    = 'ext/mkrf_conf.rb'
end
