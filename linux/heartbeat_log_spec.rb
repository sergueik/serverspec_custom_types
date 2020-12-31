if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

# see also Logback JSON encoder and appenders
# https://github.com/logstash/logstash-logback-encoder
context 'Heartbeat log Check Command' do
  class_name = 'Heartbeat'
  log_dir   = '/tmp'
  log_file  = '/tmp/heartbeat-test.json'
  log_file2 = '/tmp/heartbeat-other.json'
  log_entry = "{\"logEventType\":\"#{class_name}\", \"timestamp\":\"Thu Dec 31 13:28:51 EST 2020\"}"
  before(:all) do
  Specinfra::Runner::run_command( <<-EOF
      LOGFILE2='#{log_file2}'
    > /dev/null cd '#{log_dir}'
    LOGFILE='#{log_file}'
    cat /dev/null > $LOGFILE2
    # initialize files
    for CNT in  $(seq 1 3)
    do
      echo '#{log_entry}' | tee -a $LOGFILE
    done
    1>&2 ls -ltrd dir_*
  EOF
  )
  end
  context 'Variations' do

    # failing when multiple files are present because 
    # grep will prepend found pattern with the file path
    describe command "grep '#{class_name}' #{log_dir}/heartbeat-*.json | tail -1 | jq '.timestamp'" do
        its(:exit_status) { should eq 4 } # 
        its(:stdout) { should be_empty }
        its(:stderr) { should contain 'parse error: Invalid numeric literal' }
    end

    # working only when there isn't any redundant log files - 
    # tail expects singlefile argument 
    describe command "tail -100 #{log_dir}/heartbeat-*.json | grep '#{class_name}' | tail -1 | jq '.timestamp'" do
      its(:exit_status) { should eq 0 }
        its(:stdout) { should be_empty }
        its(:stderr) { should contain 'tail: option used in invalid context' }
    end
    
    # longer command but working stable
    describe command "grep '#{class_name}' #{log_dir}/heartbeat-*.json /dev/null | cut -d ':' -f2\\-100| tail -1 | jq '.timestamp'" do
      its(:exit_status) { should eq 0 }
      [
        'Thu Dec 31 13:28:51 EST 2020',
      ].each do |data|
        its(:stdout) {  should contain data }
      end
    end
  end
end
