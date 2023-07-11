require 'spec_helper'
"# Copyright (c) Serguei Kouzmine"

context 'zookeeper' do

  # see also: https://github.com/bloomberg/zookeeper-cookbook/blob/master/test/integration/default/serverspec/default_spec.rb
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
    it { should be_directory }
    it { should be_readable.by_user('zookeeper') }
  end

  describe service('zookeeper') do
    it { should be_enabled.with_level(3) }
    # common Ruby way of dispatching calls to methods 
    # 'check_is_running_under_init'
    # 'check_is_enabled_under_init'->service, level
    # located in the module "Specinfra::Command::Module::Service::Init"
    # via the evaluations like
    # under = under ? "_under_#{under.gsub(/^under_/, '')}" : ''
    # https://github.com/mizzy/serverspec/blob/master/lib/serverspec/type/service.rb
    it { should be_running.under('init') }
    it { should be_enabled.under('init').with_level(3) }
  end
  describe port '2181' do
    it {should be_listeningi.with('tcp') }
  end
end
