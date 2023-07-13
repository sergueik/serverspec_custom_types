require 'spec_helper'
# Copyright (c) Serguei Kouzmine

# TODO: find equivalent utility for Debian
context 'systemd-detect-virt utility', :if => ['centos', 'redhat','ubuntu'].include?(os[:family]) do
  describe file '/usr/bin/systemd-detect-virt' do
    it { should be_file }
    it { should be_executable }
  end	
  # see also: https://www.cyberforum.ru/shell/thread3119624.html
  describe command('systemd-detect-virt') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match Regexp.new('(?:none|oracle|kvm)', Regexp::IGNORECASE) }
  end

end



