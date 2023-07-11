context 'Execute embedded Ruby from Puppet Agent' do
# Copyright (c) Serguei Kouzmine
  context 'With LOAD_PATH' do
    lines = [
      'answer: 42',
      'status: changed'
    ]

    if os[:arch] == 'i386'
      # 32bit environment,
      # NOTE: also using Puppet Community Edition
      puppet_home = 'C:/Program Files/Puppet Labs/Puppet Enterprise'
    else
      # 64-bt Puppet Enterprise
      puppet_home = 'C:/Program Files (x86)/Puppet Labs/Puppet Enterprise'
    end
    # This path is for Puppet 3.2
    puppet_statedir = 'C:/ProgramData/PuppetLabs/puppet/var/state'
    last_run_report = "#{puppet_statedir}/last_run_report.yaml"
    rubylib = "#{puppet_home}/facter/lib;#{puppet_home}/hiera/lib;#{puppet_home}/puppet/lib;"
    rubyopt = 'rubygems'
    script_file = 'c:/windows/temp/test.rb'
    ruby_script = <<-EOF
`$LOAD_PATH.insert(0, '#{puppet_home}/facter/lib')
`$LOAD_PATH.insert(0, '#{puppet_home}/hiera/lib')
`$LOAD_PATH.insert(0, '#{puppet_home}/puppet/lib')
require 'yaml'
require 'puppet'
require 'pp'

# Do basic smoke test
puts 'Parse YAML string'
pp YAML.load(<<-'END_DATA'
---
answer: 42
END_DATA
)

puts 'Parse YAML string'
puts "Generate YAML\\n" +  YAML.dump({'answer'=>42})


# Read Puppet Agent last run report
data = File.read('#{last_run_report}')

# Parse
puppet_transaction_report = YAML.load(data)
# Get metrics
metrics = puppet_transaction_report.metrics
puts 'Puppet Agent last metrics:'
pp metrics
# Show resources
puppet_resource_statuses = puppet_transaction_report.resource_statuses
puts 'Puppet Agent last resources:'
pp puppet_resource_statuses.keys
# Get summary
raw_summary =  puppet_transaction_report.raw_summary
puts 'Puppet Agent last run summary:'
pp raw_summary
# Get status
status = puppet_transaction_report.status
puts 'Puppet Agent last run status: ' +  status

EOF

  Specinfra::Runner::run_command(<<-END_COMMAND
  @"
  #{ruby_script}
"@ | out-file '#{script_file}' -encoding ascii

  END_COMMAND
  )


    describe command("iex \"ruby.exe '#{script_file}'\"") do
    if os[:arch] == 'i386'
      # 32bit environment,
      # NOTE: also using Puppet Community Edition
      let(:path) { 'C:/Program Files/Puppet Labs/Puppet/sys/ruby/bin' }
    else
      # 64-bt Puppet Enterprise
      let(:path) { 'C:/Program Files (x86)/Puppet Labs/Puppet Enterprise/sys/ruby/bin' }
    end
      lines.each do |line|
        its(:stdout) do
          should match  Regexp.new(line.gsub(/[()]/,"\\#{$&}").gsub('[','\[').gsub(']','\]'))
        end
      end
    end
  end
end
