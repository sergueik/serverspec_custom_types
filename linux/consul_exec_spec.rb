require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Consul' do
  context 'Consul Response Headers' do
    name = 'X-Consul-Effective-Consistency'
    value = 'leader'
    describe command(<<-EOF
      curl -I -X GET http://localhost:8500/v1/health/state/any
    EOF
    ), Specinfra::Runner::run_command("ps ax | grep consu[l]").exit_status.eql?(0)  do
      its(:stdout) { should contain /#{name}: #{value}/i }
    end
  end
  context 'Consul Execs' do
    describe command(<<-EOF
      MESSAGE='start on runlevel'
      CONFIG_FILE='/etc/init/consul.conf'
      consul exec -verbose \\
      \\( grep -q \\"$MESSAGE\\" \\"$CONFIG_FILE\\" \\) \\&\\& \\( DATA=\\$\\( hostname -f \\)\\; /usr/bin/printf \\"MARKER: \\%s\\" \\$DATA \\) | grep 'MARKER'
  
    EOF
    ), Specinfra::Runner::run_command("ps ax | grep consu[l]").exit_status.eql?(0)  do
      its(:stdout) { should contain 'agent-one: MARKER: node1' }
    end
  end
end

