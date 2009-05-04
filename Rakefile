require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/contrib/rubyforgepublisher'
require 'rake/contrib/sshpublisher'
require 'fileutils'
require 'lib/smallcage'
require 'spec'
require 'spec/rake/spectask'

include FileUtils

NAME              = "smallcage"
AUTHORS           = ["SAITO Toshihiro", "gom", "KOSEKI Kengo"]
EMAIL             = "smallcage@googlegroups.com"
DESCRIPTION       = "Lightweight CMS package."
RUBYFORGE_PROJECT = "smallcage"
HOMEPATH          = "http://www.smallcage.org"
BIN_FILES         = %w(smc)

VERS              = SmallCage::VERSION::STRING
REV = File.read(".svn/entries")[/committed-rev="(d+)"/, 1] rescue nil
CLEAN.include ['**/.*.sw?', '*.gem', '.config']
RDOC_OPTS = [
	'--title', "#{NAME} documentation",
	"--charset", "utf-8",
	"--opname", "index.html",
	"--line-numbers",
	"--main", "README.txt",
	"--inline-source",
]

task :default => [:test]
task :package => [:clean]

spec = Gem::Specification.new do |s|
	s.name              = NAME
	s.version           = VERS
	s.platform          = Gem::Platform::RUBY
	s.has_rdoc          = true
	s.extra_rdoc_files  = ["README.txt", "History.txt"]
	s.rdoc_options     += RDOC_OPTS + ['--exclude', '^(examples|extras)/']
	s.summary           = DESCRIPTION
	s.description       = DESCRIPTION
	s.authors           = AUTHORS
	s.email             = EMAIL
	s.homepage          = HOMEPATH
	s.executables       = BIN_FILES
	s.rubyforge_project = RUBYFORGE_PROJECT
	s.bindir            = "bin"
	s.require_path      = "lib"
	#s.autorequire       = ""
	s.test_files        = Dir["spec/*_spec.rb"]

	#s.add_dependency('activesupport', '>=1.3.1')
	#s.required_ruby_version = '>= 1.8.2'

	s.files = %w(Rakefile README.txt History.txt License.txt) +
		Dir.glob("{bin,doc,lib,test,project,spec}/**/*")

	s.extensions = FileList["ext/**/extconf.rb"].to_a
end

Rake::GemPackageTask.new(spec) do |p|
	p.need_tar = true
	p.gem_spec = spec
end

task :install do
	name = "#{NAME}-#{VERS}.gem"
	sh %{rake package}
	sh %{sudo gem install pkg/#{name}}
end

task :uninstall => [:clean] do
	sh %{sudo gem uninstall #{NAME}}
end


Rake::RDocTask.new do |rdoc|
	rdoc.rdoc_dir = 'html'
	rdoc.options += RDOC_OPTS
	rdoc.template = "resh"
	#rdoc.template = "#{ENV['template']}.rb" if ENV['template']
	if ENV['DOC_FILES']
		rdoc.rdoc_files.include(ENV['DOC_FILES'].split(/,\s*/))
	else
		rdoc.rdoc_files.include('README.txt', 'History.txt')
		rdoc.rdoc_files.include('lib/**/*.rb')
		rdoc.rdoc_files.include('ext/**/*.c')
	end
end

desc "Publish to RubyForge"
task :rubyforge => [:rdoc, :package] do
	require 'rubyforge'
	Rake::RubyForgePublisher.new(RUBYFORGE_PROJECT, 'bluemark').upload
end

desc 'Package and upload the release to rubyforge.'
task :release => [:clean, :package] do |t|
	v = ENV["VERSION"] or abort "Must supply VERSION=x.y.z"
	abort "Versions don't match #{v} vs #{VERS}" unless v == VERS
	pkg = "pkg/#{NAME}-#{VERS}"

	require 'rubyforge'
	rf = RubyForge.new.configure
	puts "Logging in"
	rf.login

	c = rf.userconfig
#	c["release_notes"] = description if description
#	c["release_changes"] = changes if changes
	c["preformatted"] = true

	files = [
		"#{pkg}.tgz",
		"#{pkg}.gem"
	].compact

	puts "Releasing #{NAME} v. #{VERS}"
	rf.add_release RUBYFORGE_PROJECT, NAME, VERS, *files
end

desc 'Show information about the gem.'
task :debug_gem do
	puts spec.to_ruby
end

desc 'Update gem spec'
task :gemspec do
  open("#{NAME}.gemspec", 'w').write spec.to_ruby
end

desc "Run the specs under ./spec/"
Spec::Rake::SpecTask.new do |t|
  t.libs << "lib"
  t.spec_opts = ['--options', "spec/spec.opts"]
  t.spec_files = FileList['spec/*_spec.rb']
end
