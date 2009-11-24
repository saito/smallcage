task :default => "smc:update"

namespace :smc do
  desc "Update SmallCage project."
  task :update do
    system "smc update"
  end

  desc "Clean SmallCage project."
  task :clean do
    system "smc clean"
  end
end


