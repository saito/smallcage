
namespace :csv do

  task :require do
    require "csv"
    require "yaml"
  end

  task :sample_update => [:require] do
  end

end


def csv_to_smc(source, dir, label = false, skip = 0, fnamecol = 0)
  @colname = nil
  CSV.foreach(source) do |raw|
  end
end


