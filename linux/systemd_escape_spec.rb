require 'spec_helper'
require 'fileutils'

# https://www.freedesktop.org/software/systemd/man/systemd-escape.html
# https://serverfault.com/questions/714592/how-does-this-variable-escaping-work-in-a-systemd-unit-file
# https://www.freedesktop.org/software/systemd/man/systemd.service.html
context 'Escaping backticks and special systemd varialbles' do
  context 'Conversion' do
    [
      '`date +%F`', # this one survives
      '`date +%Y%m%d_%H%M%S`', # this one gets filled to unrecognizable way by systemd's own special var interpolation
      '\`date +%Y%m%d_%H%M%S\`', # this is the deferred execution of the date argument
      # can be identified by presence of the '\x52' and '\x60'
      # \x5c\x60date\x20\x2b\x25Y\x25m\x25d_\x25H\x25M\x25S\x5c\x60
      # The deferred date command
      # the argument -Xloggc:/opt/tomcat/logs/log-\`date +%Y%m%d_%H%M%S\`.log
      # is rejected by java loader with the error
      # Invalid file name for use with -Xloggc: Filename can only contain the characters
      # [A-Z][a-z][0-9]-_%[p|t]
      # Note t%p or %t can only be used once
      'log-%t.log', # will fail some tests
      # https://blog.gceasy.io/2016/11/15/rotating-gc-log-files/
      # explains -Xloggc:/opt/tomcat/logs/log-%t.log
      # for YYYY-MM-DD_HH-MM-SS
    ].each do |option|
      it {should_not match Regexp.new('\\\\x[0-9a-d]+', Regexp::IGNORECASE )}
      describe command ("systemd-escape '#{option}'") do
        its(:exit_status) { should be 0 }
        its(:stdout) { should match Regexp.new('\\\\x[0-9a-d]+', Regexp::IGNORECASE ) }
        its(:stderr) { should be_empty }
      end
      it 'and it should contain escaped string' do
        expect(command("systemd-escape '#{option}'").stdout).to match Regexp.new('\\\\x[0-9a-d]+', Regexp::IGNORECASE )
      end
    end
  end
  context 'Reverse' do
    {
      'aps-my\\x20application' => 'aps/my application',
      '\\x60date\\x20\\x2b\\x25F\\x60' => '`date +%F`',
    }.each do |encoded_option, option|
      # TODO: extract the encoded_option from configuration instead of passing directly
      describe command ("systemd-escape -u '#{encoded_option}'") do
        # https://stackoverflow.com/questions/56254952/does-serverspec-support-expectations-or-do-i-have-to-use-should
        its(:exit_status) { is_expected.to be 0 }
        its(:stdout) { is_expected.to match Regexp.new(Regexp.escape(option), Regexp::IGNORECASE ) }
        its(:stderr) { should be_empty }
      end
    end
  end
  # TODO: exercise processes to find out the options passed
  context 'Inspection' do
    # use a replica of existing systemd script to embed the argument
    script_path = '/etc/systemd/system/multi-user.target.wants'
    service_unit = 'postgresql'
    script_filename = "#{service_unit}.service"
    script = "#{script_path}/#{script_filename}"
    sample_script_data = <<-EOF
      [Unit]
      Description=PostgreSQL database server
      After=network.target

      [Service]
      Type=forking

      User=postgres
      Group=postgres

      # Port number for server to listen on
      Environment=PGPORT=5432

      # Location of database directory
      Environment=PGDATA=/var/lib/pgsql/data

      OOMScoreAdjust=-1000

      ExecStartPre=/usr/bin/postgresql-check-db-dir ${PGDATA}
      ExecStart=/usr/bin/pg_ctl start -D ${PGDATA} -s -o "-p ${PGPORT}" -l\\x5c\\x60date\\x20\\x2b\\x25Y\\x25m\\x25d_\\x25H\\x25M\\x25S\\x5c\\x60 -w -t 300
      ExecStop=/usr/bin/pg_ctl stop -D ${PGDATA} -s -m fast
      ExecReload=/usr/bin/pg_ctl reload -D ${PGDATA} -s

      TimeoutSec=300

      [Install]
      WantedBy=multi-user.target
    EOF

    before(:each) do
      $stderr.puts "Writing #{script}"
      file = File.open(script, 'w')
      file.puts sample_script_data
      file.close
      system('systemctl daemon-reload')
    end
    describe command (<<-EOF
      systemctl --no-page -o cat show '#{service_unit}'
    EOF
    ) do
      its(:exit_status) { should be 0 }
      its(:stdout) { should_not match Regexp.new('\\\\x[0-9a-d]+', Regexp::IGNORECASE ) }
      its(:stderr) { should be_empty }
    end
    # TODO: systemctl restart tomcat and successful healthcheck
  end
end
