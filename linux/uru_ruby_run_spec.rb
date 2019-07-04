require 'spec_helper'
context 'Run Ruby in RVM session' do
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '/tmp'
    ruby  --version
    1>/dev/null 2>/dev/null popd

  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should be_empty }
    its(:stdout) { should contain Regexp.new 'ruby 2.[0-5].\dp\d+' }
  end
end
