require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Packages' do
  context 'installed by gem provider' do
    {
      'linux-kstat' => '0.1.3',
      'sensu-plugin' => nil,
    }.each do |package_name, package_version|
      describe command("/bin/gem list --installed --local #{package_name}") do
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
        its(:stdout) { should match /true/ }
      end
      describe command("/bin/gem list --local #{package_name}") do
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
          its(:stdout) { should match Regexp.new(package_name) }
        if package_version
          its(:stdout) { should match Regexp.new(package_version) }
        end
      end
      describe package(package_name) do
        # specinfra issue ?
        if package_version
          it { should be_installed.by('gem').with_version(package_version)  }
        else
          it { should be_installed.by('gem') }
        end
      end
    end
  end
  context 'modules installed by npm' do
    # based on https://github.com/kaimingchua/serverspec-tests/blob/master/spec/ec2-18-224-84-79.us-east-2.compute.amazonaws.com/sample_spec.rb
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
    [
      'express',
    ].each do |node_module|
      # NOTE: encode': "\xE2" from ASCII-8BIT to UTF-8 (Encoding::UndefinedConversionError)
      # TODo: use iconv
      describe command( "npm list #{node_module} -g | strings") do
        its(:stdout) { should match /#{package}@[\d\.]+\s*$/ }
        # WARN npm is likely to print massive list of various unmet dependencies to STEDRR 
        # its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
      end
    end
  end
end
