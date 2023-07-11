require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

$DEBUG = true

context 'Consul service checks configuration tests' do

  consul_service_alias = 'dummy'
  consul_service_check_script_name = "#{consul_service_alias}-health-check-handler.sh"
  script_basedir = '/tmp'
  consul_config_dir = '/etc/consul.d'
  consul_config_file = "#{consul_config_dir}/config.json"
  consul_service_check_config_file = "#{consul_config_dir}/service_#{consul_service_alias}.json"

  context 'Consul args shell script' do

    service_check_script_data=<<-EOF
      #!/bin/bash

      DEBUG=0
      SELF=$(basename $0)
      PROCNAME=${1:-#{consul_service_alias}}
      PROCMASK=$(echo $PROCNAME | sed 's|\\([a-z0-9]\\)$|\\[\\1\\]|')

      if [[ $DEBUG -ne 0 ]]
      then
        echo "PROCNAME=${PROCNAME}"
        echo "PROCMASK=${PROCMASK}"
        /bin/ps -ef | grep $PROCMASK | grep -v $SELF
        # sometimes there is flipped order of command and output redirect
        # it is a bad idea
        echo ">/dev/null /bin/ps -ef | grep $PROCMASK | grep -v $SELF"
        >/dev/null /bin/ps -ef | grep $PROCMASK | grep -v $SELF
        echo $?

        echo "/bin/ps -ef | grep $PROCMASK | grep -v $SELF > /dev/null"
        /bin/ps -ef | grep $PROCMASK | grep -v $SELF > /dev/null
        echo $?
      fi
      /bin/ps -ef | grep $PROCMASK | grep -v $SELF > /dev/null
      if [[ $? -ne 0 ]]
      then
        echo "${PROCNAME} failing."
        exit 1
      else
        echo "${PROCNAME} is running."
        exit 0
      fi
    EOF

    before(:each) do
      filepath = "#{script_basedir}/#{consul_service_check_script_name}"
      $stderr.puts "Writing "#{filepath}"
      file = File.open(filepath, 'w')
      file.puts service_check_script_data
      file.close
      File.chmod(0755, filepath )
    end
    describe command(<<-EOF
      #{consul_service_check_script_name} '#{consul_service_alias}'
    EOF
    ) do
      let(:path) { "/bin:/usr/bin:/sbin:#{script_basedir}"}
      its(:stdout) { should contain "#{consul_service_alias} failing" }
      its(:exit_status) { should eq 1 }
      its(:stderr) { should be_empty }
    end
  end
  context 'Consul configuration' do
    # the config data is not realistic

    consul_config_data =<<-EOF
      {
        "datacenter": "dc",
        "data_dir": "/opt/consul",
        "log_level": "INFO",
        "node_name": "discovery",
        "server": true,
        "enable_local_script_checks": true,
        "watches": [
          {
            "type": "checks",
            "handler": "#{script_basedir}/#{consul_service_check_script_name}"
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
    EOF
    # based on https://www.consul.io/docs/agent/services.html
    consul_service_check_data =<<-EOF
      {
        "service": {
          "id": "redis",
          "name": "redis",
          "tags": ["primary"],
          "address": "",
          "meta": {
            "meta": "for my service"
          },
          "port": 8000,
          "enable_tag_override": false,
          "checks": [
            {
              "args": ["#{script_basedir}/#{consul_service_check_script_name}"],
              "interval": "10s"
            }
          ],
          "kind": "connect-proxy",
          "proxy_destination": "redis",
          "proxy": {
            "destination_service_name": "redis",
            "destination_service_id": "redis1",
            "local_service_address": "127.0.0.1",
            "local_service_port": 9090,
            "config": {},
            "upstreams": []
          },
          "connect": {
            "native": false,
            "sidecar_service": {},
            "proxy": {
              "command": [],
              "config": {}
            }
          },
          "weights": {
            "passing": 5,
            "warning": 1
          },
          "token": "233b604b-b92e-48c8-a253-5f11514e4b50"
        }
      }
    EOF
    before(:each) do
      $stderr.puts "Writing #{consul_service_check_config_file}"
      file = File.open(consul_service_check_config_file, 'w')
      file.puts consul_service_check_data
      file.close
      # TODO: permissions
      $stderr.puts "Writing #{consul_config_file}"
      file = File.open(consul_config_file, 'w')
      file.puts consul_config_data
      file.close
    end

    describe file(script_basedir) do
      it { should be_directory }
    end
    describe file("#{script_basedir}/#{consul_service_check_script_name}") do
      it { should be_file }
    end
    describe command(<<-EOF
      jq < '#{consul_config_file}' '.enable_local_script_checks'
    EOF
    ) do
      its(:stdout) { should contain 'true' }
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
    end
    describe command(<<-EOF
      jq < '#{consul_service_check_config_file}' '.service.checks[].args[]'
    EOF
    ) do
      its(:stdout) { should contain "#{script_basedir}/#{consul_service_check_script_name}" }
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
    end
  end
end