require 'spec_helper'

context 'Augeas Resource Execution' do

  systemd_home = '/usr/lib/systemd/system'
  unit_name = 'mysqld.service'
  aug_script = '/tmp/example.aug'
  unit_file = "#{systemd_home}/#{unit_name}"
  # NOTE: this is a fragment of a real systemd unit, not for prod use
  unit_file_cotents = <<-EOF
  [Unit]
Description=MySQL Server
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target
Alias=mysql.service

[Service]
User=mysql
Group=mysql

Type=forking

PIDFile=/var/run/mysqld/mysqld.pid

# Disable service start and stop timeout logic of systemd for mysqld service.
TimeoutSec=0

# Execute pre and post scripts as root

# Needed desired user to own the PIDFile

# Needed to create system tables
ExecStartPre=/usr/bin/mysqld_pre_systemd

# Start main service
ExecStart=/usr/sbin/mysqld --daemonize --pid-file=/var/run/mysqld/mysqld.pid $MYSQLD_OPTS

  EOF
  lens = 'Systemd.lns'

  setting_path = 'Service/PermissionsStartOnly'
  program=<<-EOF
    set /augeas/load/Systemd/lens "#{lens}"
    set /augeas/load/Systemd/incl #{unit_file}
    load
    set /files#{unit_file}/#{setting_path}/value 'true'
    save
    ls /files#{unit_file}/#{setting_path}[value= 'true']
  EOF
  describe command(<<-EOF
    echo '#{unit_file_contents}' > #{unit_file}
    echo '#{program}' > #{aug_script}
    augtool A -f #{aug_script}
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:stdout) { should match 'dummy' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end
end