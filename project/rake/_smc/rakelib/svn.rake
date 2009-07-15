
namespace :svn do

  # _dir.smc 
  #   svnignore: *.html # set recursively.
  #   svnignore_current: .project # add only current dir. 
  #   svnignore_reset: true # ignore parent directory settings.
  #   
  # You can use list.
  #   svnignore:
  #     - *.html
  #     - *.xml
  desc "svn propset svn:ignore ..."
  task :ignore do
    set_svnignore
  end

  desc "confirm svn commands."
  task :ignore_dryrun do
    set_svnignore(true)
  end

end



def load_svnignores(loader, path)
  dirs = loader.load_dirs(Pathname.new(path) + "child_dummy") # XXX
  ignores = []
  dirs.reverse.each do |d|
    data = d["svnignore"]
    ignores << data unless data.to_s.empty?
    break if d["svnignore_reset"]
  end
  data = dirs.last["svnignore_current"]
  unless data.to_s.empty?
    ignores << data
  end
  
  ignores.flatten!
  ignores.uniq!
  ignores.sort!
  return ignores
end

def set_svnignore(dryrun = false)
  loader = SmallCage::Loader.new(".")
  
  exec_svn(loader, ".", dryrun)
  Dir.glob("**/") do |f|
    exec_svn(loader, f, dryrun)
  end
end

def exec_svn(loader, f, dryrun)
  return if f =~ %r{^_smc/}
  svnignores = load_svnignores(loader, f).join("\n")
  return if svnignores.empty?
  cmd = "svn propset svn:ignore '#{svnignores}' #{f}"
  puts cmd
  return if dryrun
  puts "FAILED: #{cmd}" unless system cmd
end

