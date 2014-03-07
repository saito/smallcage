namespace :cache do

  desc "Delete all cache files."
  task :clean => :require do
    pat = SmallCage::CacheFilter::TARGET_PATTERN
    list = FileList[pat]
    list.each do |path|
      to = path.pathmap("%{--latest$,-*}X%x")
      outfiles = FileList[to]
      outfiles = SmallCage::CacheFilter.outfiles(path, outfiles)
      outfiles.each do |f|
        puts "(cache)D #{f[0]}"
        File.delete(f[0])
      end
    end
  end

  desc "Delete old cache files."
  task :delete_old => :require do
    pat = SmallCage::CacheFilter::TARGET_PATTERN
    list = FileList[pat]
    list.each do |path|
      to = path.pathmap("%{--latest$,-*}X%x")
      outfiles = FileList[to]
      outfiles = SmallCage::CacheFilter.outfiles(path, outfiles)
      outfiles.pop
      outfiles.each do |f|
        puts "(cache)D #{f[0]}"
        File.delete(f[0])
      end
    end
  end

  task :require do
    require File.dirname(__FILE__) + "/../filters/cache_filter.rb"
  end

  desc "Update *--latest.* files."
  task :update => [:require] do
    pat = SmallCage::CacheFilter::TARGET_PATTERN

    # Fix filenames. (site--latest.css.smc -> site--latest.css -> site-123.css)
    smclist = FileList["#{pat}.smc"]
    system "smc update" unless smclist.empty?
    list = FileList[pat]
    SmallCage::CacheFilter.create_cache(list, ENV["DRYRUN"])

    # Apply cache filter. Rewrite links. (site--latest.css.smc -> site--latest.css)
    system "smc update"

    # Copy updated file (site--latest.css -> site-123.css)
    smclist = smclist.map {|f| f[0 .. -5]}
    SmallCage::CacheFilter.create_cache(smclist, ENV["DRYRUN"])
  end
end