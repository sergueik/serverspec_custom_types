require 'spec_helper'
require 'fileutils'

context 'Systemd' do
  context 'Basic Systemd' do
    # see also https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units
    context 'Exact Match test' do
      unit = 'httpd'
      system_etc_dir = '/etc/systemd/system'
      system_lib_dir = '/usr/lib/systemd/system'
    
      # in some occasions devops have a habit of making the systemd service unit
      # be short-circuited to a link to /dev/null.
      # Ensure this is not the case
      describe file "#{system_etc_dir}/#{unit}.service" do
        it { should_not be_symlink }
        it { should_not be_linked_to('/dev/null') }
      end	
      # instruct systemctl to format the output as list
      # NOTE: for AppDynamics and Java Agent see
      # https://zeroturnaround.com/rebellabs/how-to-inspect-classes-in-your-jvm/
      # https://github.com/zeroturnaround/callspy/
      # https://docs.appdynamics.com/
      # AppDynmics simply suggests make its javaagent jar the instrumentation agent
      # that utilizes the defaault Instrumentation API provided by the JVM
      # by executing the JavaAgent class premain method that will be called before
      # the main method of the subject application class
      # and allowing "java.lang.instrument.Instrumentation"
      # instrument bytecode of the application
      # to allow appDynamics do its wonders to the available JVM instance:
      # JAVA_OPTS=...-javaagent:/home/appdynamics/AppServerAgent/javaagent.jar...
      # this demistifies the mehanism behind AppDynamics's "information points"
      # metrics extracted around of the particular target application method invocation
      info = {
        'Description' => 'The Apache HTTP Server',
        'LoadState'   => 'loaded',
        'ActiveState' => 'active', # 'inactive'  or 'failed' when stopped,
        'After'       => 'system.slice remote-fs.target tmp.mount network.target basic.target -.mount nss-lookup.target systemd-journald.socket',
        # NOTE: the actual sysctl output will contain pid and start_time leading the include? expectation to fail
        # 'ExecStart'   => '{ path=/usr/sbin/httpd ; argv[]=/usr/sbin/httpd $OPTIONS -DFOREGROUND ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
        'ExecReload'  => '{ path=/usr/sbin/httpd ; argv[]=/usr/sbin/httpd $OPTIONS -k graceful ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
        'ExecStop'    => '{ path=/bin/kill ; argv[]=/bin/kill -WINCH ${MAINPID} ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
      }
      info_regexp = '(:?' + info.keys.join('|') + ')'
      command = "systemctl --no-page show #{unit} | grep -E '#{info_regexp}=' "
      # processing of the command output follows
      service_info = command(command).stdout
      $stderr.puts ('inspecting:' + "\n" + '------' + "\n" + service_info + "\n" + '------' +" \n")
      info.each do |key,val|
        status = -1
        # status = true
        line = key + '=' + val
        if service_info.include? line
          $stderr.puts ('found: ' + line )
          status = 0
        else
          $stderr.puts ('Cannot find ' + line)
        end
        describe key do
          $stderr.puts ('status = ' + status )
          subject { status }
          it { should eq 0 }
        end
      end
    end
  end
  context 'Systemd timers' do
    # https://www.freedesktop.org/software/systemd/man/systemd.timer.html
    # https://www.putorius.net/using-systemd-timers.html
    # https://www.certdepot.net/rhel7-use-systemd-timers/
    context 'systemd timer' do
      system_etc_dir = '/etc/systemd/system'
      system_lib_dir = '/usr/lib/systemd/system'
      # on a bare bones Centos there aren't any timers in '/etc/systemd/system'
      unit = 'systemd-tmpfiles-clean'
      describe file "#{system_lib_dir}/#{unit}.timer" do
        it { should be_file }
        [
          '[Unit]',
          'Description=.*',
          '[Timer]',
          '(?:OnBootSec|OnStartupSec|OnUnitInactiveSec|OnUnitActiveSec|OnActiveSec)=(?:\d+min|\d+h)',
          'OnCalendar=daily',
          'RandomizedDelaySec=(?:\d+min|\d+sec|\d+h)',
          "Unit=#{unit}.service",
          '[Install]',
          'WantedBy=multi-user.target',
        ].each do |line|
          # NOTE: some of the entries may be optional or mutually-exclusive
          # TODO: count matches to rank unit a good matching
          # its(:content) { should match Regexp.new(Regexp.escape(line)) }
          its(:content) { should match Regexp.new("^\s*" +line) }
        end
      end
      # may be in system_etc_dir
      describe file "#{system_lib_dir}/#{unit}.service" do
        it { should be_file }
      end
      describe command "journalctl -u #{unit}" do
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
        its(:stdout) { should_not contain '-- No entries --' }
      end
    end
  end
  # https://vic.demuzere.be/articles/using-systemd-user-units/
  # https://www.brendanlong.com/systemd-user-services-are-amazing.html
  # https://www.juev.org/2015/05/25/systemd/ (in Russian)
  # https://www.linux.org.ru/forum/desktop/9268186 (in Russian)
  # https://github.com/zoqaeski/systemd-user-units
  # https://github.com/ahkok/user-session-units
  # https://itsecforu.ru/2020/04/05/%F0%9F%90%A7-%D0%BA%D0%B0%D0%BA-%D0%B7%D0%B0%D0%BF%D1%83%D1%81%D1%82%D0%B8%D1%82%D1%8C-%D1%81%D0%B5%D1%80%D0%B2%D0%B8%D1%81%D1%8B-systemd-%D0%B1%D0%B5%D0%B7-%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2/ (in Russian)
  # https://medium.com/@alexeypetrenko/systemd-user-level-persistence-25eb562d2ea8
  # 
  context 'Systemd expressions' do
    # https://www.freedesktop.org/software/systemd/man/systemd-escape.html
    # https://serverfault.com/questions/714592/how-does-this-variable-escaping-work-in-a-systemd-unit-file
    # https://www.freedesktop.org/software/systemd/man/systemd.service.html
    context 'Escaping backticks and special systemd variables' do
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
  end
end

