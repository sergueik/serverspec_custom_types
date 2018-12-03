require 'spec_helper'
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
  
  describe 'Service checks' do
    custom_headers.each do |name, value|
      describe command(<<-EOF
        curl -I -X GET http://localhost:8500/v1/health/state/any
      EOF
      ), Specinfra::Runner::run_command("ps ax | grep consu[l]").exit_status.eql?(0) do
        its(:stdout) { should contain "#{name}: #{value}" }
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