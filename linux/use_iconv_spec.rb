require 'spec_helper'

context 'Sysctl tests' do
  service_unit = 'httpd'
  # default output of systemctl needs unicode sanitation
  context 'Converting output unicode clean' do
    describe command("systemctl status '#{service_unit}' | iconv --from-code UTF8 --to-code US-ASCII -c -") do
      its(:stdout) { should contain Regexp.new(Regexp.escape('* httpd.service - The Apache HTTP Server')) }
    end
    begin
      # the next expectation may fail and abort the process when locale is wrong
      describe command("systemctl status #{service_unit}") do
        its(:stdout) { should contain Regexp.new(Regexp.escape("* httpd.service - The Apache HTTP Server")) }
      end
    rescue => e
      $stderr.puts 'Exception (ignored) ' + e.to_s
    end
  end

  # alternatively command systemctl to format output in the list format
  context 'Structural output processing' do
    # some settings e.g. Environment for java launchers typically have multiple tokens -Dkey=value in the rhs separated by a space
    # systemctl show uses \x20 for those settings to indicate whitespaces in the output like e.g.
    # Environment=JAVA_HOME=/usr/lib/jvm/java JAVA_OPTS=\x20Djava.utils.prefs.userRoot=/opt/app/.java\x20-Djava.utils.prefs.systemRoot=/opt/app/.java...
    # where it won't be practical to match the whole line to evaluate specific settings in the applcation jvm configuration
    # for clean expectation expression it is probably better to tokenize the output keeping one token per line

    describe command("systemctl --no-page -o cat show '#{service_unit}' | sed 's|\\x20|\\n|g'") do
      [
        '-Djava.utils.prefs.systemRoot=/opt/app/.java',
        '-Djava.utils.prefs.userRoot=/opt/app/.java',
      ].each do |line|
        its(:stdout) { should contain Regexp.new(line, Regexp::IGNORECASE ) }
      end
    end
    # a longer example
    info = {
      'Description'     => 'The Apache HTTP Server',
      'LoadState'       => 'loaded',
      'ActiveState'     => 'active', # 'inactive'  or 'failed' when stopped,
      'After'           => 'system.slice remote-fs.target tmp.mount network.target basic.target -.mount nss-lookup.target systemd-journald.socket',
      # 'Environment'     =>   not in default systemctl configuration of Apache httpd
      # often is configured via KEY=VALUE array in /etc/systemd/system/httpd.service. These get concatenated in the systemctl show output
      'EnvironmentFile' => '/etc/sysconfig/httpd (ignore_errors=no)',
      # NOTE: the actual sysctl output will contain pid and start_time making the include? fail
      # 'ExecStart'       => '{ path=/usr/sbin/httpd ; argv[]=/usr/sbin/httpd $OPTIONS -DFOREGROUND ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
      'ExecReload'      => '{ path=/usr/sbin/httpd ; argv[]=/usr/sbin/httpd $OPTIONS -k graceful ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
      'ExecStop'        => '{ path=/bin/kill ; argv[]=/bin/kill -WINCH ${MAINPID} ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }',
    }
    info_regexp = '(:?' + info.keys.join('|') + ')'
    command = "systemctl --no-page -o cat show '#{service_unit}' | sed 's|\\x20|\\n|g' | grep -E '#{info_regexp}=' "
    context 'Exact Match Evaluation' do
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
    context 'Regexp processing' do
      describe command(command) do
        info.each do |key,val|
          # #escape does not work
          # its(:stdout) { should contain Regexp.new(key + '=' + Regexp.escape(val)) }
          its(:stdout) { should contain key + '=' + val }
          # #escape will not handle properly
          line = val
                {
            '\\' => '\\\\\\\\',
            '$'  => '\\\\$',
            '+'  => '\\\\+',
            '?'  => '\\\\?',
            '-'  => '\\\\-',
            '*'  => '\\\\*',
            '{'  => '\\\\{',
            '}'  => '\\\\}',
            '('  => '\\(',
            ')'  => '\\)',
            '['  => '\\[',
            ']'  => '\\]',
            ' '  => '\\s*',
          }.each do |s,r|
            line.gsub!(s,r)
          end
          # home-brewed regexp escape does not work
          # its(:stdout) do
          #   should contain Regexp.new(key + '=' + line, Regexp::IGNORECASE )
          # end
        end
      end
    end
  end
end
