require 'spec_helper'
# Copyright (c) Serguei Kouzmine
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end

# based on: https://groups.google.com/forum/#!topic/selenium-users/SKs7-5tOeiE

context 'Chromedriver session creation test' do
  # This expects the chromedriver to be installed in the PATH
  version = '77.0.3865.40'
  default_port = '9515'
  describe command(<<-EOF
    # killall chromedriver
    chromedriver &
    PID=$!
    kill -HUP $PID
  EOF
  ) do
      let(:path) { '/bin:/usr/bin:/sbin:/usr/local/bin'}
      its(:stdout) { should match Regexp.new(Regexp.escape("Starting ChromeDriver #{version}")) }
      its(:stdout) { should match Regexp.new("on port #{default_port}") }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
  end
  describe command(<<-EOF
    # killall chromedriver
    chromedriver &
    PID=$!
    curl --header "Content-Type: application/json" --request POST --data '{"desiredCapabilities":{"browserName":"chrome"}}' http://localhost:#{default_port}/session | jq '.' -
    # will launch chrome if DISPLAY is set
    killall chrome
    kill -HUP $PID
  EOF
  ) do
      let(:path) { '/bin:/usr/bin:/sbin:/usr/local/bin'} # does not work
      its(:stdout) { should match Regexp.new("sessionId": "[a-f0-9]+" ) }
      its(:stdout) { should match Regexp.new("version": "77.0.3865.120") }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
  end
end
