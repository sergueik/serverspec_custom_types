require 'spec_helper'


context 'Puppet lastrun report' do

  context 'Extraction of inventory from last run summary report' do

    # date -d@$(tail last_run_summary_yaml|grep 'last_run' | awk '{print $2}')
    # will return the puppet last run date time 
    # formatted like standard unix date
    # Wed Dec 9 14:00:00 EST 2020
   	   
    describe command(<<-EOF
      date -d@$(tail last_run_summary_yaml|grep 'last_run' | awk '{print $2}')
    EOF
    ) do
      let(:path) { '/opt/puppet/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/sbin:/bin:/usr/sbin:/usr/bin' }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
      its(:stdout) {should contain 'Wed Dec 9 14:00:00 EST 2020' }
    end
  end 
  # TODO: uid check
  context 'location of lastrun report' do
    describe command(<<-EOF
      puppet config print lastrunreport
    EOF
    ) do
      let(:path) { '/opt/puppet/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/sbin:/bin:/usr/sbin:/usr/bin' }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
      its(:stdout) {should contain '/var/cache/puppet/state/last_run_report.yaml' }
    end
    user = 'sergueik'
    describe command(<<-EOF
      su - #{user} sh -c 'puppet config print lastrunreport'
    EOF
    ) do
      let(:path) { '/opt/puppet/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/sbin:/bin:/usr/sbin:/usr/bin' }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
      its(:stdout) {should contain "/home/#{user}/.puppet/cache/state/last_run_report.yaml" }
    end
  end
  context 'Execute simple static check after puppet apply creates a lastrun report' do
    dummy_manifest_script = 'notify {"this is a test":}'
    before(:each) do
      Specinfra::Runner::run_command("puppet apply -e '#{dummy_manifest_script}'")
    end
    describe command(<<-EOF
      tail -10 $(puppet config print lastrunreport) | grep '^status:' | grep -v 'failed'
      tail -10 $(puppet config print lastrunreport) | grep '^status:' | grep -vq 'failed'
    EOF
    ) do
      let(:path) { '/opt/puppet/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/sbin:/bin:/usr/sbin:/usr/bin' }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
      its(:stdout) {should match /status: (?!failed)/ }
    end
  end
  context 'Master loop' do
    describe command(<<-COMMAND
      MASTERS=$(cat <<EOF
        puppetmaster1.domain.org
        puppetmaster2.domain.org
      EOF
      )

      for MASTER in $MASTERS ; do
        echo $MASTER
        # select another puppet master
        sed -i "s|server *= .*$|server = $MASTER|g" /etc/puppetlabs/puppet/puppet.conf
        puppet agent --test --no-noop | tee "/tmp/puppet.${MASTER}.log"
        AGENT_STATUS=$?
        echo "Examine agent status ${AGENT_STATUS}"
        if [[ $AGENT_STATUS -eq 4 ]]; then
          echo 'apply catalog failed'
        fi
        if [[ $AGENT_STATUS -eq 6 ]]; then
          echo 'apply catalog reported failures'
        fi
        if [[ $AGENT_STATUS -eq 1 ]]; then
          echo 'apply catalog fails'
        fi
        if [[ $AGENT_STATUS -eq 0 ]]; then
          echo "Examine last run report $(puppet config print lastrunreport)"
          tail -10 $(puppet config print lastrunreport) | grep '^status:' | grep -vq 'failed'
          if [[ $? -ne 0 ]]; then
            echo 'Puppet run failed'
          fi
        fi
        if [[ $AGENT_STATUS -eq 2 ]]; then
          echo 'apply catalog succeeded'
          exit 0
        fi
      done
    COMMAND
    ) do
      let(:path) { '/opt/puppet/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/sbin:/bin:/usr/sbin:/usr/bin' }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
      its(:stdout) {should match /apply catalog succeeded/ }
    end
  end
  context 'Execute Puppet Agent embedded Ruby to examine Last Run Report' do
    # script_file = '/tmp/test.$$.rb'
    script_file = '/tmp/test.rb'
    # Puppet version-specific path settings:
    # RHEL 6.6 x64 / Puppet 4.3
    puppet_lib_home = '/opt/puppetlabs/puppet/lib/ruby/vendor_ruby/'
    # Centos 6.5 x86 box / Puppet 3.2.3
    puppet_lib_home = '/usr/share/ruby/vendor_ruby/'

    ruby_script = <<-EOF

      \\$LOAD_PATH.insert(0, '#{puppet_lib_home}/facter/lib')
      \\$LOAD_PATH.insert(0, '#{puppet_lib_home}/hiera/lib')
      \\$LOAD_PATH.insert(0, '#{puppet_lib_home}/puppet/lib')
      require 'puppet'
      require 'yaml'
      require 'pp'
      require 'optparse'

      options = {}
      OptionParser.new do |opts|
        opts.banner = \\"Usage: example.rb [options]\\"
        opts.on(\\"-v\\", \\"--[no-]verbose\\", \\"Run verbosely\\") do |v|
          options[:verbose] = v
        end
        opts.on(\\"-rRUN\\", \\"--run=RUN\\", \\"Examine the RUN'th Puppet Run Report\\") do |_run|
          options[:run] = _run
        end
      end.parse!

      # Do add entry for basic smoke test
      result = { 'answer' => 42 }

      # Read Puppet Agent last run report
      # NOTE: escaping special characters to prevent execution by shell
      puppet_last_run_report = \\`puppet config print 'lastrunreport'\\`.chomp
      if options[:run]
        puppet_last_run_report = puppet_last_run_report + '.' + options[:run].to_s
      end
      data = File.read(puppet_last_run_report)
      # Parse Puppet Agent last run report, sanitize from
      # !ruby/object:Puppet::Util::Metric and the like

      puppet_transaction_report = YAML.load(data)

      # Get metrics
      metrics = puppet_transaction_report.metrics

      time = metrics['time']
      puts 'Times:'
      pp time.values

      events = metrics['events']
      puts 'Events:'
      pp events.values
      # puts events.values.to_yaml

      resources = metrics['resources']
      puts 'Resources:'
      pp resources.values

      puppet_resource_statuses = puppet_transaction_report.resource_statuses
      puts 'Resource Statuses:'
      pp puppet_resource_statuses.keys
      result['resources'] = puppet_resource_statuses.keys

      raw_summary = puppet_transaction_report.raw_summary
      puts 'Summary:'
      pp raw_summary

      status = puppet_transaction_report.status
      puts 'Status: ' + status

      result['status'] = status
      \\$stderr.puts YAML.dump(result)

    EOF
    before(:each) do
      # Specinfra::Runner::run_command("echo \"123\" > /tmp/a.txt")
      # TODO: provide example of differently quoted shell script
      Specinfra::Runner::run_command("echo \"#{ruby_script}\" > #{script_file}")
    end

    context 'First Run' do
      lines = [
        'answer: 42',
        'Status: changed',
        '"failed" =>0', # resources
        '"failure"=>0', # events
      ]

      # for multi-runs
      # ruby #{script_file} --run=1 2> /tmp/a.log
      # for debugging
      # ruby #{script_file} 2> /tmp/a.log
      # for integration into a custom type: print a valid YAML to stderr
      describe command(<<-EOF
        export RUBYOPT='rubygems'
        ruby #{script_file}
      EOF
      ) do
        # NOTE: Ruby may not be available system-wide, but it will be present in the Agent
        let(:path) { '/opt/puppet/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin:/sbin:/bin:/usr/sbin:/usr/bin' }
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
        lines.each do |line|
          its(:stdout) do
            should match  Regexp.new(line.gsub(/[()]/,"\\#{$&}").gsub('[','\[').gsub(']','\]'))
          end
        end
      end
    end
  end
end
# /opt/puppetlabs/puppet/lib/ruby/vendor_ruby/puppet/transaction/event.rb:36:in
# `initialize_from_hash': undefined method `[]'
# for #<Puppet::Transaction::Event:0x00000001f5d088> (NoMethodError)
# ...
# from from /tmp/test.rb:32:in `<main>'
# puppet_transaction_report = YAML.load(data)
