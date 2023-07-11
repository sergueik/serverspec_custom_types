require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require_relative '../type/puppet_helper'
context 'Puppet run' do
  describe  puppet_helper( 'filename' ) do
    its(:summary) { should_not be_nil}
    its(:summary) { should include( 'version', 'puppet', 'resources' )}
    # its(:status) { should eq 403 }
    its(:raw_data) { should contain 'failure: 0' }
  end
end
