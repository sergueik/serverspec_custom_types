require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'
require 'json'
require 'yaml'
require 'ostruct'

$DEBUG = true

# this example may be considred a bulding block for specinfra  monitored_by? -style expectaton with consul
# NOTE: need a working cluster of consul agents to validate

context 'Consul Response Headers' do

  consul_config_dir = '/etc/consul.d'
  consul_config_file = "#{consul_config_dir}/config.json"
  custom_headers = {
    'Access-Control-Allow-Origin' => '*',
    'X-Frame-Options'             => 'sameorigin, allow-from https://example.com/',
    'X-Xss-Protection'            => '1; mode=block'
  }
  describe 'Service health state response' do
    node = %x|hostname|.chomp
    peer_node = 'consul2' # peer node
    # uses REST call in case the default TCP port 8500 is disabled and unclear how to compose the
    # alternate consul info command
    # NOTE: tricky to compose with bash shell quoting,e.g.
    # jq: error: syntax error, unexpected INVALID_CHARACTER, expecting $end
    # and similar errors
    # healthy output would look like
    # {
    #   "Node": "$CONSUL_NODE_NAME",
    #   "CheckID": "serfHealth",
    #   "Status": "passing",
    #   "Notes":"",
    #   "Output": "Agent alive and reachable",
    #   'ServiceID": "",
    #   "SerciceName": ""
    #   "ServiceTags": [],
    #   "CreatrIndex": 5
    #   "CreatrIndex": 5
    # }

    describe command(<<-EOF
      CONSUL_NODE_NAME = '#{node}'
      curl -I -X GET http://localhost:8500/v1/health/state/any | jq '.[]| select(.Node == "#{node}")'
    EOF
    ), Specinfra::Runner::run_command('ps ax | grep consu[l]').exit_status.eql?(0) do
   end
  end
  describe 'Service checks' do
    custom_headers.each do |name, value|
      describe command(<<-EOF
        curl -I -X GET http://localhost:8500/v1/health/state/any
      EOF
      ), Specinfra::Runner::run_command("ps ax | grep consu[l]").exit_status.eql?(0) do
        its(:stdout) { should contain /#{name}: #{value}/i }
      end
      describe command(<<-EOF
        curl -k -I -X GET https://127.0.0.1:8543/v1/agent/services
      EOF
      ), Specinfra::Runner::run_command('ps ax | grep consu[l]').exit_status.eql?(0) do
        its(:stdout) { should contain Regexp.new("#{name}: #{value}", Regexp::IGNORECASE  )  }
      end
    end
  end

  describe 'Consul Configuration' do
    # mock one unless real one exist
    # NOTE: cannot touch 'before'
    before(:each) do
      # NOTE: currently before(:each) does not work with this code.
      # Need to crerate datafile manually
      # mock of the /etc/consul.d/service_web_config.json
      # https://www.consul.io/docs/agent/options.html
      # NOTE: modifiers very fragile - does not work here either
      unless Specinfra::Runner::run_command("ps ax | grep consu[l]").exit_status.eql?(0)
        $stderr.puts "Creaing mock of the #{consul_config_file}"
        Specinfra::Runner::run_command(<<-EOF
          ps ax | grep -q consu[l]
          if [ $? -ne 0 ] ; then
            1>2 echo "Creaing mock of the #{consul_config_file}"
            1 > /dev/null 2> /dev/null mkdir '#{consul_config_dir}'
            # Example full config.json
            cat <<END>#{consul_config_file}
{
  "datacenter": "dc",
  "data_dir": "/opt/consul",
  "log_level": "INFO",
  "node_name": "discovery",
  "server": true,
  "watches": [
    {
      "type": "checks",
      "handler": "/usr/bin/dummy-health-check-handler.sh"
    }
  ],
  "ports": {
    "http": 8500,
    "https": -1
  },
  "http_config": {
    "response_headers": {
      "X-XSS-Protection": "1; mode=block",
      "X-Frame-Options": "sameorigin, allow-from https://example.com/",
      "Access-Control-Allow-Origin": "*"
    }
  }
}
END
    fi
    # shell HEREDOC delimiter must stay in the first column
      EOF
      )
      end
    end
    custom_headers.each do |name, value|
      # https://stedolan.github.io/jq/manual/#example27	
      describe command(<<-EOF
        jq -r '.http_config.response_headers| to_entries[] | [.key, .value] | @csv' '#{consul_config_file}'
      EOF
      ) do
        its(:stdout) { should contain "\"#{name}\",\"#{value}\"" }
        its(:exit_status) { should eq 0 }
        its(:stderr) { should be_empty }
      end
    end
  end
end

context 'Misc. consul configuration tests' do
  consul_config_dir = '/etc/consul.d'
  consul_config_file = "#{consul_config_dir}/config.json"

  # minimal consul config
  # {
  #   "bootstrap_expect": 2,
  #   "client_addr": "0.0.0.0",
  #   "data_dir": "/tmp/consul",
  #   "server": true,
  #   "retry_join": [
  #     "192.168.51.10",
  #     "192.168.51.11"
  #   ],
  #   "ui": true,
  #   "verify_incoming": false,
  #   "verify_outgoing": false
  # }
  #
  {
   'ui'               => true,
   'bootstrap_expect' => 2,
   'data_dir'         => '/tmp/consul',
   } .each do |name, value|
    describe command("jq '.#{name}' '#{consul_config_file}' | tr -d '\"'") do
      its(:stdout) { should contain /"?#{value}"?/ }
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
    end
  end
  [
    '192.168.51.10',
    '192.168.51.11'
  ].each do |hostname|
    # demo of some jq transformations
    describe command("jq '.retry_join| join(\",\") |split(\",\")' '#{consul_config_file}'") do
      its(:stdout) { should contain /"#{hostname}"/ }
      its(:exit_status) { should eq 0 }
    end
  end
end
