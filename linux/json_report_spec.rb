if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'SAX HTML tests' do
  tmp_path = '/tmp'
  json_file = "#{tmp_path}/report.json"

  json_data = <<-EOF
{
  "report": {
    "data": [
      {
        "date": "2019-10-01",
        "value": 1
      },
      {
        "date": "2019-10-02",
        "value": 1
      },
      {
        "date": "2019-10-03",
        "value": 1
      },
      {
        "date": "2019-10-04",
        "value": 1
      },
      {
        "date": "2019-10-05",
        "value": 1
      },
      {
        "date": "2019-10-06",
        "value": 1
      },
      {
        "date": "2019-10-07",
        "value": 1
      },
      {
        "date": "2019-10-08",
        "value": 1
      },
      {
        "date": "2019-10-09",
        "value": 1
      },
      {
        "date": "2019-10-10",
        "value": 1
      },
      {
        "date": "2019-10-11",
        "value": 1
      },
      {
        "date": "2019-10-11",
        "value": 1
      },
      {
        "date": "2019-10-12",
        "value": 1
      },
      {
        "date": "2019-10-13",
        "value": 1
      },
      {
        "date": "2019-10-14",
        "value": 1
      },
      {
        "date": "2019-10-15",
        "value": 1
      },
      {
        "date": "2019-10-16",
        "value": 1
      },
      {
        "date": "2019-10-17",
        "value": 1
      },
      {
        "date": "2019-10-18",
        "value": 1
      },
      {
        "date": "2019-10-19",
        "value": 1
      },
      {
        "date": "2019-10-20",
        "value": 1
      },
      {
        "date": "2019-20-21",
        "value": 1
      },
      {
        "date": "2019-20-22",
        "value": 1
      },
      {
        "date": "2019-20-23",
        "value": 1
      },
      {
        "date": "2019-20-24",
        "value": 1
      },
      {
        "date": "2019-20-25",
        "value": 1
      },
      {
        "date": "2019-20-26",
        "value": 1
      },
      {
        "date": "2019-20-27",
        "value": 1
      },
      {
        "date": "2019-20-28",
        "value": 1
      },
      {
        "date": "2019-20-29",
        "value": 1
      },
      {
        "date": "2019-20-30",
        "value": 1
      }
    ]
  }
}
  EOF
  before(:each) do
    $stderr.puts "Writing #{json_file}"
    file = File.open(json_file, 'w')
    file.puts json_data
    file.close
  end
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '#{tmp_path}'    
    REPORT_DATES=$(jq '.report.data[]|.date' < '#{json_file}' | sort )
    REPORT_DATES_UNIQ=$(jq '.report.data[]|.date' <report.json | sort -u )
    if [[ $(echo $REPORT_DATES|wc -w) -ne $(echo $REPORT_DATES_UNIQ|wc -w) ]]; then echo 'Duplicate dates detected'; fi
    1>/dev/null 2>/dev/null popd
  EOF

  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) {  should contain 'Duplicate dates detected' }
  end
end
