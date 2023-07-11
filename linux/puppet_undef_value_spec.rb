require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Puppet type exercise' do
  describe command( <<-EOF
    puppet apply -e 'class test(Variant[String, Undef]$value = undef){ if $value { notify {"value \\"${value}\\" is true": }} else { notify {"value \\"${value}\\" is false": }  } } class {"test": }'
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'value "" is false' }
    # Use of 'hiera.yaml' version 3 is deprecated. It should be converted to version 5
    # its(:stderr) { should be_empty }
  end
  describe command( <<-EOF
    puppet apply -e 'class test(Variant[String, Undef]$value = undef){ if $value { notify {"value \\"${value}\\" is true": }} else { notify {"value \\"${value}\\" is false": }  } } class {"test":  value => "" }'
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'value "" is true' }
    its(:stderr) { should be_empty }
  end
end
