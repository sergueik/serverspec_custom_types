require 'spec_helper'
# Copyright (c) Serguei Kouzmine

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

context 'Rsyslog configuration file' do
  # real conf file, ubuntu
  conf_file_system = '/etc/rsyslog.d/50-default.conf'
  # Mockup of a fragment '/etc/rsyslog.d/50-default.conf'
  conf_file = '/tmp/a.conf'
  logfile = '/tmp/runner.log'

  before(:each) do
    # NOTE: zero indent in the following command
    Specinfra::Runner::run_command( <<-EOF
      LOGFILE='#{logfile}'
      CONFFILE=#{conf_file}
      cat /dev/null > $LOGFILE
      echo "Creating ${CONFFILE}" | tee -a $LOGFILE
      touch $CONFFILE
      cat /dev/null > $CONFFILE
      echo "Writing sample syslog data into ${CONFFILE}" | tee -a $LOGFILE
      # NOTE: strip the lines line below from the example:
      # The named pipe /dev/xconsole is for the \`xconsole\' utility.  To use it
      cat <<DATA | tee -a $CONFFILE
  daemon.*;mail.*;\\\\
        news.err;\\\\
        *.=debug;*.=info;\\\\
        *.=notice;*.=warn       |/dev/xconsole


DATA
# NOTE: no indent
  echo 'Done.' | tee -a $LOGFILE
    EOF
    )
  end
  describe command (<<-EOF
    grep -vi '^ *#' '#{conf_file}' | sed '$!N;/\\\\ *$/s/\\\\ *\\n/ /g' | tr -d '\\t' | tr -d ' '

  EOF
  ) do
  #    RegexpError:
  #     target of repeat operator is not specified: /*.=debug;*.=info;*.=notice;*.=warn|.*dev.*xconsole/m
  #  its(:stdout) { should contain  '*.=debug;*.=info;*.=notice;*.=warn|/dev/xconsole' }

    its(:stdout) { should match Regexp.new(Regexp.escape('*.=debug;*.=info;*.=notice;*.=warn|/dev/xconsole')) }
  end
  # the lense is under '/opt/puppetlabs/puppet/share/augeas/lenses/dist'
  # named 'rsyslog.aug'
  # NOTE: does not appear possible to load /tmp/a.conf:
  # augtool> ls /files/
  # etc/ = (none)
  # lib/ = (none)
  # boot/ = (none)
  # opt/ = (none)
  # root/ = (none)
  # usr/ = (none)  
  # 
  context 'Augeas get command' do

    # default yum install
    aug_script = '/tmp/example.aug'
    # real conf file, centos
    conf_file_system = '/etc/rsyslog.d/listen.conf'
    aug_path = '$SystemLogSocketName'
    # trying basic augtool get command
    # http://augeas.net/docs/references/lenses/files/tests/test_rsyslog-aug.html#Test_Rsyslog
    # https://github.com/hercules-team/augeas/wiki/Path-expressions#Path_Expressions_by_Example
    aug_path_response = '/run/systemd/journal/syslog'

    program=<<-EOF
      set /augeas/load/rsyslog/lens "rsyslog.lns"
      set /augeas/load/rsyslog/incl "#{conf_file}"
      load
      get /files#{conf_file}/#{aug_path}
      print /files#{conf_file_system}/#{aug_path}
      dump-xml /files#{conf_file_system}/#{aug_path}
    EOF

    describe command(<<-EOF
      echo '#{program}' > #{aug_script}
      augtool -A -f #{aug_script}
    EOF
    ) do
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
      its(:stdout) { should_not match Regexp.escape( "/files#{conf_file_system}/#{aug_path} = (o)") }
      its(:stdout) { should match Regexp.escape( "/files#{conf_file_system}/#{aug_path} = " + aug_path_response ) }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
end