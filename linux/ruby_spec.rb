require 'spec_helper'


context 'Puppet Last Run Report' do
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
