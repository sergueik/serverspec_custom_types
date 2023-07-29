require 'spec_helper'
# Copyright (c) Serguei Kouzmine

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

  # origin: https://github.com/DE-IBH/imvirt
  # Perl module for virtualization detection, available as imvirt on Debian/ Ubuntu
  describe package('imvirt'), :if => os[:family] == 'ubuntu' do
    it { should be_installed }
  end
  describe command('imvirt') , :if => os[:family] == 'ubuntu' do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match Regexp.new('(?:Physical|KVM|VirtualBox|Microsoft)', Regexp::IGNORECASE) }
  end
  describe package('virt-what') do
    it { should be_installed }
  end
  describe command('virt-what') do
    its(:exit_status) { should eq 0 }
    # NOTE: this test will fail on physical machine
    its(:stdout) { should match Regexp.new('(?:kvn|virtualbox|hyperv)', Regexp::IGNORECASE) }
  end
end



