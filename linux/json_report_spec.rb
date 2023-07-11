if File.exists?( 'spec/windows_spec_helper.rb')
# Copyright (c) Serguei Kouzmine
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'Json daily report tests' do

  tmp_path = '/tmp'
  json_file = "#{tmp_path}/report.json"
  context 'invalid dates' do
    json_data = <<-EOF
      {
        "report": {
          "data": [
            {
              "date": "2019-02-29",
              "value": 1
            },
            {
              "date": "2019-11-31",
              "value": 1
            }
          ]
        }
      }
    EOF
    json_file = "#{tmp_path}/report3.json"
    before(:each) do
      $stderr.puts "Writing #{json_file}"
      file = File.open(json_file, 'w')
      file.puts json_data
      file.close
    end
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd '#{tmp_path}'
      REPORT_DATES=$(jq '.report.data[]|.date' < '#{json_file}' | tr -d '"' )
      for REPORT_DATE in $REPORT_DATES ; do
        date +%Y-%m-%d --date "${REPORT_DATE}" 1> /dev/null
        if [ $? -ne 0 ]; then echo 'Invalid date detected'; fi
      done
      1>/dev/null 2>/dev/null popd
    EOF

    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) {  should contain 'Invalid date detected' }
      its(:stderr) {  should_not contain 'parse error'}
      its(:stderr) {  should_not be_empty }
    end
  end      
  context 'gaps of report dates' do
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
              "date": "2019-10-05",
              "value": 1
            }
          ]
        }
      }
    EOF
    json_file = "#{tmp_path}/report2.json"
    before(:each) do
      $stderr.puts "Writing #{json_file}"
      file = File.open(json_file, 'w')
      file.puts json_data
      file.close
    end
    describe command(<<-EOF
      1>/dev/null 2>/dev/null pushd '#{tmp_path}'
      REPORT_BEGIN_DATE=$(jq '.report.data[]|.date' <'#{json_file}' | sort | head -1 | tr -d '"' )
      REPORT_END_DATE=$(jq '.report.data[]|.date' <'#{json_file}' | sort | tail -1 | tr -d '"')

      REPORT_END_DATE=$(date +%Y-%m-%d -d "${REPORT_END_DATE} + 1 day")

      REPORT_END_EPOCH=$(date +%s --date "${REPORT_END_DATE}" );
      REPORT_BEGIN_EPOCH=$(date +%s --date "${REPORT_BEGIN_DATE}");

      NUM_CALENDAR_DAYS=$(expr \\( $REPORT_END_EPOCH - $REPORT_BEGIN_EPOCH \\) / 86400 )
      echo "Expect ${NUM_CALENDAR_DAYS} in report"

      REPORT_DATES_UNIQ=$(jq '.report.data[]|.date' <report.json | sort -u )
      if [[ $NUM_CALENDAR_DAYS -ne $(echo $REPORT_DATES_UNIQ|wc -w) ]]; then echo 'Date gaps detected'; fi
      1>/dev/null 2>/dev/null popd
    EOF

    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) {  should contain 'Date gaps detected' }
    end
  end  
  context 'duplicaton of report dates' do
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
              "date": "2019-10-11",
              "value": 1
            },
            {
              "date": "2019-10-11",
              "value": 1
            },
            {
              "date": "2019-10-30",
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
      REPORT_DATES_UNIQ=$(jq '.report.data[]|.date' <'#{json_file}' | sort -u )
      if [[ $(echo $REPORT_DATES|wc -w) -ne $(echo $REPORT_DATES_UNIQ|wc -w) ]]; then echo 'Duplicate dates detected'; fi
      1>/dev/null 2>/dev/null popd
    EOF

    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) {  should contain 'Duplicate dates detected' }
    end
  end
end
