task :default => :smcupdate

task :smcupdate do
  system "smc update"
end
