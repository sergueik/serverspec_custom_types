require 'spec_helper'

context 'Augeas Puppet agent noop setting of the node' do

  puppet_conf_dir = '/etc/puppetlabs/puppet'
  puppet_conf_file = "#{puppet_conf_dir}/puppet.conf"

  aug_script = '/tmp/test.aug'
  puppet_agent_setting = 'agent/noop'
  program=<<-EOF
    get /files#{puppet_conf_file}/#{puppet_agent_setting}
    set /files#{puppet_conf_file}/#{puppet_agent_setting} false
    save
    set /files#{puppet_conf_file}/#{puppet_agent_setting} false
    save
    get /files#{puppet_conf_file}/#{puppet_agent_setting}
  EOF
  describe command(<<-EOF
    echo '#{program}' > #{aug_script}
    augtool -f #{aug_script}
    # NOTE: bug in augool ?
    # setting to the new value 
    #    /files/etc/puppetlabs/puppet/puppet.conf/agent/noop = false
    # save gets rejected, but the second time it it not:
    #    error: Failed to execute command
    #    saving failed (run 'errors' for details)
    # but atttmted to save for the second time it it not:
    #    /files/etc/puppetlabs/puppet/puppet.conf/agent/noop = true
    #
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:stdout) { should match '/files/etc/puppetlabs/puppet/puppet.conf/agent/noop = true' }
    its(:stdout) { should match '/files/etc/puppetlabs/puppet/puppet.conf/agent/noop = false' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end
end