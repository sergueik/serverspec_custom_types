require 'spec_helper'

context 'Exact Match test' do
  # alternatively command systemctl to format output in the list format
  info = {
    'Description' => 'The Apache HTTP Server',
    'LoadState'   => 'loaded',
    'ActiveState' => 'active', # 'inactive'  or 'failed' when stopped,
    'After'       => 'system.slice remote-fs.target tmp.mount network.target basic.target -.mount nss-lookup.target systemd-journald.socket',
    # NOTE: the actual sysctl output will contain pid and start_time making the include? fail
    # 'ExecStart'   => '{ path=/usr/sbin/httpd ; argv[]=/usr/sbin/httpd $OPTIONS -DFOREGROUND ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
    'ExecReload'  => '{ path=/usr/sbin/httpd ; argv[]=/usr/sbin/httpd $OPTIONS -k graceful ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
    'ExecStop'    => '{ path=/bin/kill ; argv[]=/bin/kill -WINCH ${MAINPID} ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
  }
  info_regexp = '(:?' + info.keys.join('|') + ')'
  command = "systemctl --no-page show httpd | grep -E '#{info_regexp}=' "
  service_info = command(command).stdout
  $stderr.puts "inspecting:\n------\n#{service_info}\n------\n"
  info.each do |key,val|
    status = -1
    # status = true
    line = key + '=' + val
    if service_info.include? line
      $stderr.puts "found: #{line}"
      status = 0
    else
      $stderr.puts 'Cannot find ' + line
    end
    describe key do
    $stderr.puts "status = #{status}"
    subject { status }
    it { should eq 0 }
    end
  end
end

