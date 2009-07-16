
namespace :csv do

  task :require do
    require "csv"
    require "yaml"
  end

  # csv_to_smc sample task.
  task :sample_update => [:require] do
    csv_to_smc("_smc/sample.csv") {|data,rownum| "path/to/contents/#{"%04d" % (rownum - 1)}_#{data["key"]}.smc" }
  end

end


def csv_to_smc(csv_file, label_row = 0, skip_rows = 1)
  labels = nil
  rownum = -1
  CSV.foreach(csv_file) do |row|
    rownum += 1
    labels = row if label_row == rownum
    next if rownum < skip_rows

    if labels
      data = {}
      labels.each_with_index do |label,i|
        data[label] = row[i].to_s
      end
    else
      data = row.map {|cell| cell.to_s }
    end
    if block_given?
      fname = yield(data,rownum)
    else
      fname = data[0]
    end
    File.open(fname, "w") do |io|
      io << data.to_yaml
    end
  end

end
