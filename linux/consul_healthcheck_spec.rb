require 'spec_helper'

context 'Consul REST API' do
  fields = %w|
    Status
    Name
    CheckID
    Node
  |
  service = 'web'
  describe command(<<-EOF
    SERVICE='#{service}'
    2>/dev/null curl http://127.0.0.1:8500/v1/health/checks/$SERVICE | jq '.'| tee '/tmp/data.json'
    FIELDS='#{fields}'
    for FIELD in $FIELDS ; do
      echo $FIELD
      cat '/tmp/data.json' | jq ".[]|.$FIELD" -
    done
  EOF
  ) do
    its(:stdout) { should contain 'passing' }
    its(:stdout) { should contain 'service:web' }
  end
  # NOTE: no service check for consul itself 
  # http://127.0.0.1:8500/v1/health/checks/consul
  # see also:
  # https://www.consul.io/docs/agent/checks.html
end
