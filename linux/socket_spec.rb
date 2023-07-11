require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'using ss to display socker information'  do
  # NOTE: -p requires sudo
  # on Centos the '--no-header' option is unrecognized
  describe command(<<-EOF
    ss --ipv4 --tcp --listening --processes
  EOF
  ) do
    # on Debian and Centos the ss is found in different directories
    let(:path) { '/bin:/sbin'}
    # LISTEN     0      128        *:ssh                      *:*
    # users:(("sshd",pid=951,fd=3))
    its(:stdout) { should match Regexp.new(Regexp.escape('*:ssh')) }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end
  describe command 'ss -l -4 -t -n -p' do
    let(:path) { '/bin:/sbin'}
     # LISTEN     0      128        *:22                      *:*
     # users:(("sshd",pid=951,fd=3))
    its(:stdout) { should match Regexp.new(Regexp.escape('*:22')) }
    its(:stdout) { should match Regexp.new('users:\(\("sshd",pid=\d+,fd=3\)\)') }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end
end

