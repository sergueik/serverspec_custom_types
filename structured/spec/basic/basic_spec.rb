require 'spec_helper'

context 'basic' do
  describe port 22  do
    it { should be_listening }
  end
end



