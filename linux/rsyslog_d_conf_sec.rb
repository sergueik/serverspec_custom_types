  require 'spec_helper'

  $DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

  context 'Rsyslog configuration file' do
    # real conf file
    conf_file = '/etc/rsyslog.d/50-default.conf'
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
    end