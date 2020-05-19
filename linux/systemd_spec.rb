require 'spec_helper'

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

