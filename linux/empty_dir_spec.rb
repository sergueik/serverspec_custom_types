require 'spec_helper'

# count the files in the directory
context 'Directory without files' do
  path_to_dir = '/var/run/sshd'
  describe file(path_to_dir) do
    it { should be_a_directory }

    it 'should be an empty directory' do
      Dir.glob("#{path_to_dir}/*").should eq []
    end
  end
end
