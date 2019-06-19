require 'spec_helper'
require 'pp'
require 'json'
require 'yaml'

# Performs data extraction from YAML with the help of jq
# https://medium.com/@frontman/how-to-parse-yaml-string-via-command-line-374567512303
# Alternatively
# https://github.com/kislyuk/yq
# (in Python)
# for Debian based
# sudo add-apt-repository ppa:rmescandon/yq
# sudo apt update
# sudo apt install yq -y
# https://github.com/ThomasCrevoisier/jq-js for in the browser jq like
# https://github.com/jim80net/yq
# for HTML see also
# https://github.com/ericchiang/pup
# (in go)
context 'YAML' do
  context 'Using jq to traverse YAML' do
    datafile = '/tmp/example.yaml'
    before(:each) do
      # NOTE: indent and white space matters
      Specinfra::Runner::run_command( <<-EOF
        cat<<END>'#{datafile}'
---
node-ad8c3125:
  datacenter: 'miami'
  consul_node_name: consul-service-discovery-server
  branch_name: 'uat'
  environment: 'prod'
  dc: 'bcp'
  param1:
    - 'a'
    - 'b'
    - 'c'
  param2:
    key1: 'value1'
    key2: 'value2'
  param3: 'data'
END
      EOF
      )
    end
    describe command(<<-EOF
      cat '#{datafile}' | ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' | \\
      jq '.[]| select( .datacenter | contains("miami")) | .param1 | @csv '
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new('"\\\\"a\\\\",\\\\"b\\\\",\\\\"c\\\\"', Regexp::IGNORECASE) }
      its(:stderr) { should_not match 'jq: error: syntax error' }
    end

  end
  # NOTE: YAML 'anchors' feature explained in https://learnxinyminutes.com/docs/yaml/
  context 'YAML with anchors' do
    datafile = '/tmp/anchors.yaml'
    before(:each) do
      # NOTE: YAML data is indent and white space sensitive
      # based on: https://raw.githubusercontent.com/andrewwardrobe/serverspec-extra-types/master/.gitlab-ci.yml
      Specinfra::Runner::run_command( <<-EOF
        cat<<END>'#{datafile}'
---
dc: &dc
  datacenter: 'miami'
node: &node
  <<: *dc
  environment: 'prod'
END
      EOF
      )
    end
    describe command(<<-EOF
      cat '#{datafile}' | ruby -rpp -ryaml -rjson -e 'yaml_object = YAML.load(ARGF); pp yaml_object'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stderr) { should be_empty }
    end
    describe command(<<-EOF
      yamllint '#{datafile}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should contain 'YamlLint found no errors' }
      its(:stderr) { should be_empty }
      # [DEPRECATION] This gem has been renamed to optimist and will no longer be supported. Please switch to optimist as soon as possible.
    end
  end
end
