require 'spec_helper'


context 'Zabbix Server and Web' do
  # based on https://github.com/y-araki-git/serverspec-os-init/blob/master/spec/init/zabbix_spec.rb
  context 'Packages' do
    {
      'zabbix-frontend-php' => nil,
      'zabbix-agent' => '4.2.4',  # TODO: define 'latest'
      'zabbix-server-mysql'  => '4.2.4',
    }.each do |package_name,package_name|
      if version.nil?
        describe package package_name do
          it { should be_installed.with_version version }
        end
      else
        describe package package_name do
          it { should be_installed }
        end
      end
    end
  end

  context 'Services' do
    [
      'zabbix-agent',
      'zabbix-server',
    ].each do |service_name|
      describe service service_name do
        it { should be_enabled }
        it { should be_running }
      end
    end
  end
  context 'Ports' do
    [
      10051,
      10050,
      80
    ].each do |port_number|
      describe port port_number do
        it { should be_listening.with('tcp') }
        it { should be_running }
      end
    end
  end

  context 'Configuration' do
    conf_dir = '/etc/zabbix'
    context 'Agentd' do
      config_file = "#{conf_dir}/zabbix_agentd.conf"
      describe file config_file do
        its { should be_file }
      end
      %w|
        Server=#{zabbix_server},#{zabbix_server_2}
        ServerActive=#{zabbixserver}
        Hostname=#{%x|hostname|}
        AllowRoot=1
        RefreshActiveChecks=120
        EnableRemoteCommands=1
      |.each do |line|
        describe file config_file do
          its { should be_file }
          its(:content) { should match /^#{conf}/ }
        end
      end
      describe file "#{conf_dir}/zabbix_agentd.d" do
        its { should be_directory }
      end
      describe file "#{conf_dir}/zabbix_agentd.d/userparameter_mysql.conf" do
        its { should be_file }
      end
    end
    context 'Server' do
      config_file = "#{conf_dir}/zabbix_server.conf"
      describe file config_file do
        its { should be_file }
      end
      {
        'LogFile' => '/var/log/zabbix/zabbix_server.log',
        'PidFile' => '/var/run/zabbix/zabbix_server.pid',
        'DBName'  => 'zabbix',
        'DBUser'  => 'zabbix',
      }.each do |setting, value|
      describe file config_file do
        # alternatively an negative look-behind lookup:
        # zabbix configs are typically 95% of commented lines
        its(:content) { should match /^ *#{setting} *= *#{value}/ }
      end
    end
  end
  # TODO: add mysql expectations about shema Tables_in_zabbix and describe individual tables e.g. problem
  #
end
