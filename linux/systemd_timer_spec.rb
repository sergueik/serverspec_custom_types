require 'spec_helper'

# https://www.freedesktop.org/software/systemd/man/systemd.timer.html
# https://www.putorius.net/using-systemd-timers.html
# https://www.certdepot.net/rhel7-use-systemd-timers/
context 'systemd timer' do
  system_etc_dir = '/etc/systemd/system'
  system_lib_dir = '/usr/lib/systemd/system'
  # on a bare bones Centos there aren't any timers in '/etc/systemd/system'
  unit = 'systemd-tmpfiles-clean'
  describe file "#{system_lib_dir}/#{unit}.timer" do
    it { should be_file }
    [
      '[Unit]',
      'Description=.*',
      '[Timer]',
      '(?:OnBootSec|OnStartupSec|OnUnitInactiveSec|OnUnitActiveSec|OnActiveSec)=(?:\d+min|\d+h)',
      'OnCalendar=daily',
      'RandomizedDelaySec=(?:\d+min|\d+sec|\d+h)',
      "Unit=#{unit}.service",
      '[Install]',
      'WantedBy=multi-user.target',
    ].each do |line|
      # NOTE:  some of the entries may be optional or mutually-exclusive
      # TODO: count matches to rank unit a good matching
      # its(:content) { should match Regexp.new(Regexp.escape(line)) }
      its(:content) { should match Regexp.new("^\s*" +line) }
    end
  end
  # may be in system_etc_dir
  describe file "#{system_lib_dir}/#{unit}.service" do
    it { should be_file }
  end
  describe command "journalctl -u #{unit}" do
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
    its(:stdout) { should_not contain '-- No entries --' }
  end
end