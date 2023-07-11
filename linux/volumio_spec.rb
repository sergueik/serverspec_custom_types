require 'spec_helper'
"# Copyright (c) Serguei Kouzmine"

describe 'Desktop Manager' do

  describe file '/opt/volumiokiosk.sh'  do
    it { should be_file }
    it { should be_owned_by 'root' }
    [
      'openbox-session',
      "/usr/bin/chromium --disable-session-crashed-bubble --disable-infobars --kiosk --no-first-run  'http://localhost:3000'",
    ].each do |line|
      its(:content) { should match Regexp.new(line) }
    end
  end
  describe process 'chromium'  do
    it { should be_running }
    its(:user) { should eq 'volumio' }
    [
      'http://localhost:3000',
      '--kiosk'
    ].each do |line|
      its(:args) { should match Regexp.new(line) }
    end
  end

end