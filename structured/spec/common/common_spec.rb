require 'spec_helper'

describe 'common' do
  describe command 'hostname -s'  do
    its(:stdout) { should_not match /\./ }
  end
end
