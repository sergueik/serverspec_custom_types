require 'spec_helper'

$DEBUG = true

context 'Incremental report results size check' do
  json_file = '/tmp/data.json'
  json_data = {
    'results' => []
  }
  line = 'stale'
  before(:all) do
    $stderr.puts "Writing #{json_file}"
    file = File.open(json_file, 'w')
    file.puts JSON.dump(json_data)
    file.close
  end
  before(:each) do
    command = "jq '.results | length' '#{json_file}'"
    @results_length = command(command).stdout
    $stderr.puts ('Results: ' + @results_length )
    # presumably run command generating some data and appending to the report
  end
  context 'stale report' do
    # parenthesis not optional
    describe command( <<-EOF
      ORIG_LENGTH='#{@results_length}'
      RESULTS_LENGTH=$(jq '.results | length' '#{json_file}')
      if [[ $RESULTS_LENGTH -gt $ORIG_LENGTH ]]
      then
        echo 'appended'
      else
        echo 'stale'
        1>&2 echo 'stale'
      fi
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should contain line }
      its(:stdout) { should contain line }
    end
  end
end
