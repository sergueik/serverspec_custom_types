require 'spec_helper'

# based on https://github.com/kaimingchua/serverspec-tests/blob/master/spec/ec2-18-224-84-79.us-east-2.compute.amazonaws.com/sample_spec.rb
context 'npm modules' do
  node_version = 'v10.13.0'	
  node_bindir = "#{ENV['HOME']}/.nvm/versions/node/#{node_version}/bin"
  node = 'node'
  npm = 'npm'
  {
   'express' => '3.1.2',
   'json-schema' => '0.2.2',
  }.each do |npm_package,version|
    describe command("#{node} show #{npm_package} -v 2>&1") do
      let(:path) {"/bin:/usr/bin:/usr/local/bin:#{node_bindir}"}
      its(:stdout) { should be >= version }
      # NOT tested
    end
    # NOTE: standard matchers and chain op apply (check_is_installed_by_npm), 
    # but without comparison
    describe package(npm_package) do
      it { should be_installed.by('npm').with_version(version) }
    end
  end
end
