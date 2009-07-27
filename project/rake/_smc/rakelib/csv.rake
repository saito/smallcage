
namespace :csv do

  task :require do
    require "csv"
    require "yaml"
  end

  # csv_to_smc sample task.
  task :update_samples => [:require] do

    # By default, csv rows are saved as array.
    csv_to_smc("_smc/samples.csv") {|data,rownum| "samples/#{"%04d" % rownum}.html.smc" }

    # You can create hash using label_row/skip_rows parameters.
    # csv_to_smc("_smc/samples.csv", 1, 0) {|data,rownum| "samples/#{"%04d" % rownum}.html.smc" }

  end

end


def csv_to_smc(csv_file, skip_rows = nil, label_row = nil)
  labels = nil
  skip_rows ||= 0
  label_row ||= -1

  rownum = -1
  CSV.foreach(csv_file) do |row|
    rownum += 1
    labels = row.map{|cell| cell.to_s } if label_row == rownum
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
