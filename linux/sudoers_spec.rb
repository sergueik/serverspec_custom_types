require 'spec_helper'
require 'fileutils'

context 'Systemd' do

  describe command('visudo -help') do
    its(:exit_status) { should eq 0 }
  end

  # example sudoers line to verify
  # %username ALL= NOPASSWD: /bin/systemctl reload nginx
  #
  describe file('/etc/sudoers.d') do
    it { should be_directory }
    # NOTE: be_mode needs a numeric argument without leading zero
    # when leading zero present value gets read as octal number and conveted to decimal 493
    it { should_not be_mode 0755 }
    it { should be_mode 755 }
  end
  describe file('/etc/sudoers.d/README') do
    it { should be_file }
    # NOTE: be_mode needs a string argument. within the string there shold not be leading zero
    # the stat %a formatting command does not pad octal access mask to four positions
    # when the qotes is omitted the value gets read as octal number and conveted to decimal 288
    it { should_not be_mode '0440' }
    it { should be_mode '0440' }
    it { should be_mode '440' }
  end
  describe file('/etc/sudoers') do
    it { should be_file }
    it { should be_mode 440 }
    its(:content) { should include '#includedir /etc/sudoers.d' }
  end
end

