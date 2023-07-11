require 'spec_helper'
# Copyright (c) Serguei Kouzmine

$DEBUG = true

context 'Incremental report results size check' do
  json_file = '/tmp/data.json'
  json_data = {
    'answer' => 42,
    'results' => ['apple','banana','orange']
  }
  before(:all) do
    $stderr.puts "Writing #{json_file}"
    file = File.open(json_file, 'w')
    file.puts JSON.dump(json_data)
    file.close
  end
  context 'stale report' do
    before(:each) do
      command = "jq '.results | length' '#{json_file}'"
      @results_length = command(command).stdout
      $stderr.puts ('Results: ' + @results_length )
      # presumably run command generating some data and appending to the report
    end
    # parenthesis not optional
    line = 'stale'
    describe command( <<-EOF
      ORIG_LENGTH='#{@results_length}'
      RESULTS_LENGTH=$(jq '.results | length' '#{json_file}')
      if [ $RESULTS_LENGTH -gt $ORIG_LENGTH ]
      then
        echo 'appended'
      else
        echo 'stale'
      fi
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      its(:stdout) { should contain line }
    end
  end
  context 'appended report' do
    line = 'appended'
    before(:each) do
      command = "jq '.results | length' '#{json_file}'"
      @results_length = command(command).stdout
      $stderr.puts ('Results: ' + @results_length )
      # presumably run command generating some data and appending to the report
    end
    describe command( <<-EOF
      1>&2 echo ruby -rjson -e 'datafile = ARGV[0]; $stderr.puts ("Loading " + datafile ); @data = JSON.load(File.new(datafile)); @data["results"].push @data["results"][-1]; JSON.dump(@data, File.new(datafile,"w"));' '#{json_file}'

      ruby -rjson -e 'datafile = ARGV[0]; $stderr.puts ("Loading " + datafile ); @data = JSON.load(File.new(datafile)); @data["results"].push @data["results"][-1]; JSON.dump(@data, File.new(datafile,"w"));' '#{json_file}'
      ORIG_LENGTH='#{@results_length}'
      RESULTS_LENGTH=$(jq '.results | length' '#{json_file}')

      if [ $RESULTS_LENGTH -gt $ORIG_LENGTH ]
      then
        echo 'appended'
        1>&2 echo 'appended'
      else
        echo 'stale'
        1>&2 echo 'stale'
      fi
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
      its(:stdout) { should contain line }
    end
  end
  # require 'csv'
  # datafile = ARGV[0]
  # @data = CSV.read(File.new(datafile))
  # @data.push @data[-1]
  # CSV.open(datafile, 'w') { |csv| csv << @data }
end
