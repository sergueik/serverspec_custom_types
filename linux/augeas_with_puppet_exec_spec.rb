require 'spec_helper'
context 'Augeas Resource Execution' do
  systemd_home = '/usr/lib/systemd/system'
  unit_name = 'mysqld.service'
  unit_file = "#{systemd_home}/#{unit_name}"
  context 'Augtool mode' do
    # https://gist.github.com/jniesen/aecf5ee3a3f3bd55c7a84ffe4c432408
    # NOTE: this is a fragment of a real systemd unit, not for prod use
    # NOTE: indent-sensitive
    unit_file_contents = <<-EOF
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
    aug_script = "/tmp/example-#{Process.pid}.au"
    setting_path = 'Service/PermissionsStartOnly'
    comment = '\"this is comment\"'
    program=<<-EOF
set /augeas/load/o/lens '#{lens}'
set /augeas/load/o/incl '#{unit_file}'
load
set /files#{unit_file}/#{setting_path}/value 'true'
save
ls /files#{unit_file}/#{setting_path}
# NOTE: error: No match for path expression
insert #comment before /files#{unit_file}/#{setting_path}
set #comment[last()] '#{comment}'
# save
# NOTE: Error in /usr/lib/systemd/system/mysqld.service (put_failed)
    EOF
    describe command(<<-EOF
      # NOTE: echo creates problems with quote preserving
      echo '#{unit_file_contents}' > #{unit_file}
      echo '#{program}' > #{aug_script}
      augtool -A -f #{aug_script}
    EOF
    ) do
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
      its(:stdout) { should match Regexp.new(Regexp.escape('Saved 1 file(s)')) }
      its(:stdout) { should match 'value = true' }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'Puppet mode' do
    describe command(<<-EOF
  puppet apply -d -e 'augeas { "Change mysqld.service PermissionsStartOnly":
    context => "/files#{unit_file}",
    incl    => "#{unit_file}",
    lens    => "Systemd.lns",
    changes => [
      "set Service/PermissionsStartOnly/value \\"false\\""
    ],
    onlyif  => "match Service/PermissionsStartOnly[value = \\"false\\"]  size == 0",
  }'
    EOF
    ) do
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
      its(:stdout) { should match Regexp.new("Applying configuration version '\\d+'") }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
      # inspect the result
      describe file(unit_file) do
        its(:content) {should include 'PermissionsStartOnly=false' }
      end
    end
  end
end