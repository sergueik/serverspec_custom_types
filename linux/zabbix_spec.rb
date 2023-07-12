require 'spec_helper'
"# Copyright (c) Serguei Kouzmine"


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
  context 'Database' do
    database_name = 'zabbix'
    describe command( <<-EOF
      mysql -e "SELECT DISTINCT DB from mysql.db;"
    EOF
    ) do
      its (:stdout) { shoud contain database_name }
    end
    describe command( <<-EOF
      mysql -D #{database_name} -e "SELECT 1;"
    EOF
    ) do
      its (:stdout) { shoud_not match /Unknown database/ }
      its (:exit_status) { should eq 0 }
    end
  end
  context 'Processes' do
    context 'Server' do
      process_name = 'zabbix_server'
      describe command( <<-EOF
        pgrep #{process_name}
      EOF
      ) do
        [
          'alert manager',
          'alerter',# note: actually a few of such
          'configuration syncer',
          'discoverer',
          'escalator',
          'history syncer',  # a few
          'housekeeper',
          'http poller', # a few
          'lld manager',
          'lld worker', # a few
          'poller', # a few
          'preprocessing worker', # a few
          'proxy poller',
          'self-monitoring',
          'task manager',
          'trapper', # a few
          'unreachable poller', # ?
        ].each |role|
          its(:stdout) { should contain role }
          its(:exit_status) { should eq 0 }
        end
      end
      describe proces(process_name) do
        it { should be_running }
        its(:user) { should eq 'zabbix' }  # critical for some locked environments
        its(:args) { should match Regexp.new('--conf') }
      end
      describe proces(process_name) do
        it { should be_running }
        its(:user) { should eq 'zabbix' }  # critical for some locked environments
        its(:args) { should match Regexp.new('-c /etc/zabbix/zabbix_server.conf') }
      end
    end
    context 'Agent' do
      process_name = 'zabbix-agent'
      describe command( <<-EOF
        service #{process_name} status 2>/dev/null
      EOF
      ) do
        [
          'active checks',
          'collector',
          'listener', # a few
        ].each |role|
          its(:stdout) { should contain role }
           its(:exit_status) { should eq 0 }
        end
      end
      describe proces(process_name) do
        it { should be_running }
        its(:user) { should eq 'zabbix' }  # critical for some locked environments
        its(:args) { should match Regexp.new('-c /etc/zabbix/zabbix_agentd.conf') }
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
        it { should be_file }
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
          it { should be_file }
          its(:content) { should match /^#{conf}/ }
        end
      end
      describe file "#{conf_dir}/zabbix_agentd.d" do
        it { should be_directory }
      end
      describe file "#{conf_dir}/zabbix_agentd.d/userparameter_mysql.conf" do
        it { should be_file }
      end
    end
    context 'Server' do
      config_file = "#{conf_dir}/zabbix_server.conf"
      describe file config_file do
        it { should be_file }
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

# mockup for testing the spec on the node without zabbix server
#  vagrant@localhost:~$ pgrep -a zabbix
#  1577 /usr/sbin/zabbix_server -c /etc/zabbix/zabbix_server.conf
#  1584 /usr/sbin/zabbix_server: configuration syncer [waiting 60 sec for processes]
#  1585 /usr/sbin/zabbix_server: housekeeper [startup idle for 30 minutes]
#  1586 /usr/sbin/zabbix_server: timer #1 [updated 0 hosts, suppressed 0 events in 0.033044 sec, idle 59 sec]
#  1587 /usr/sbin/zabbix_server: http poller #1 [got 0 values in 0.000924 sec, idle 5 sec]
#  1588 /usr/sbin/zabbix_server: discoverer #1 [processed 0 rules in 0.004870 sec, idle 60 sec]
#  1589 /usr/sbin/zabbix_server: history syncer #1 [processed 1 values, 1 triggers in 0.004658 sec, idle 1 sec]
#  1590 /usr/sbin/zabbix_server: history syncer #2 [processed 0 values, 0 triggers in 0.000022 sec, idle 1 sec]
#  1591 /usr/sbin/zabbix_server: history syncer #3 [processed 0 values, 0 triggers in 0.000038 sec, idle 1 sec]
#  1592 /usr/sbin/zabbix_server: history syncer #4 [processed 0 values, 0 triggers in 0.000020 sec, idle 1 sec]
#  1596 /usr/sbin/zabbix_server: escalator #1 [processed 0 escalations in 0.001802 sec, idle 3 sec]
#  1598 /usr/sbin/zabbix_server: proxy poller #1 [exchanged data with 0 proxies in 0.000046 sec, idle 5 sec]
#  1599 /usr/sbin/zabbix_server: self-monitoring [processed data in 0.000044 sec, idle 1 sec]
#  1600 /usr/sbin/zabbix_server: task manager [processed 0 task(s) in 0.000767 sec, idle 5 sec]
#  1602 /usr/sbin/zabbix_server: poller #1 [got 2 values in 0.000169 sec, idle 1 sec]
#  1604 /usr/sbin/zabbix_server: poller #2 [got 0 values in 0.000015 sec, idle 1 sec]
#  1605 /usr/sbin/zabbix_server: poller #3 [got 0 values in 0.000011 sec, idle 1 sec]
#  1607 /usr/sbin/zabbix_server: poller #4 [got 0 values in 0.000010 sec, idle 1 sec]
#  1608 /usr/sbin/zabbix_server: poller #5 [got 0 values in 0.000012 sec, idle 1 sec]
#  1609 /usr/sbin/zabbix_server: unreachable poller #1 [got 0 values in 0.000047 sec, idle 5 sec]
#  1610 /usr/sbin/zabbix_server: trapper #1 [processed data in 0.000000 sec, waiting for connection]
#  1611 /usr/sbin/zabbix_server: trapper #2 [processed data in 0.000000 sec, waiting for connection]
#  1612 /usr/sbin/zabbix_server: trapper #3 [processed data in 0.000000 sec, waiting for connection]
#  1613 /usr/sbin/zabbix_server: trapper #4 [processed data in 0.000000 sec, waiting for connection]
#  1614 /usr/sbin/zabbix_server: trapper #5 [processed data in 0.000000 sec, waiting for connection]
#  1615 /usr/sbin/zabbix_server: icmp pinger #1 [got 0 values in 0.000039 sec, idle 5 sec]
#  1616 /usr/sbin/zabbix_server: alert manager #1 [sent 0, failed 0 alerts, idle 5.009681 sec during 5.009807 sec]
#  1617 /usr/sbin/zabbix_server: alerter #1 started
#  1618 /usr/sbin/zabbix_server: alerter #2 started
#  1625 /usr/sbin/zabbix_server: alerter #3 started
#  1628 /usr/sbin/zabbix_server: preprocessing manager #1 [queued 0, processed 5 values, idle 5.003593 sec during 5.003734 sec]
#  1629 /usr/sbin/zabbix_server: preprocessing worker #1 started
#  1630 /usr/sbin/zabbix_server: preprocessing worker #2 started
#  1633 /usr/sbin/zabbix_server: preprocessing worker #3 started
#  1634 /usr/sbin/zabbix_server: lld manager #1 [processed 0 LLD rules during 5.003746 sec]
#  1635 /usr/sbin/zabbix_server: lld worker #1 started
#  1640 /usr/sbin/zabbix_server: lld worker #2 started
# service zabbix-agent status
#  * zabbix-agent.service - Zabbix Agent
#     Loaded: loaded (/lib/systemd/system/zabbix-agent.service; disabled; vendor pr
#     Active: active (running) since Wed 2019-07-10 14:24:58 PDT; 1s ago
#    Process: 1896 ExecStart=/usr/sbin/zabbix_agentd -c $CONFFILE (code=exited, sta
#   Main PID: 1899 (zabbix_agentd)
#     CGroup: /system.slice/zabbix-agent.service
#             |-1899 /usr/sbin/zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf
#             |-1900 /usr/sbin/zabbix_agentd: collector [idle 1 sec]
#             |-1901 /usr/sbin/zabbix_agentd: listener #1 [waiting for connection
#             |-1902 /usr/sbin/zabbix_agentd: listener #2 [waiting for connection
#             |-1903 /usr/sbin/zabbix_agentd: listener #3 [waiting for connection
#             `-1904 /usr/sbin/zabbix_agentd: active checks #1 [idle 1 sec]
#
