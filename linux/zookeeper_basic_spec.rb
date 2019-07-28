require 'spec_helper'

# origin: https://github.com/bloomberg/zookeeper-cookbook/blob/master/test/integration/default/serverspec/default_spec.rb

# yum install https://archive.cloudera.com/cdh5/one-click-install/redhat/7/x86_64/cloudera-cdh-5-0.x86_64.rpm
# https://stackoverflow.com/questions/41611275/how-to-install-zookeeper-as-service-on-centos-7

{
  'zookeeper-server' => '3.4.5',
  'cloudera-cdh' => nil,
}.each do |name, version|
  if version.nil?
    describe package name do
      it { should be_installed }
    end
  else
    describe package name do
      it { should be_installed.with_version version }
    end
  end
end
describe file '/etc/init.d/zookeeper-server' do
  it { should be_file }
  it { should be_mode 755 }
  its(:content) {should match Regexp.new('# Default-Start: * 2 3 4 5') }
end
describe file '/var/lib/zookeeper' do
  it { should be_ddirectory }
end
describe service('zookeeper') do
  it { should be_enabled.with_level(3) }
  it { should be_running }
end
describe port '2181' do
  it {should be_listening }
end
