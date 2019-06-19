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
  context 'Using jq to process YAML' do
    datafile = '/tmp/example.yaml'
    before(:each) do
      # NOTE: indent and white space matters
      Specinfra::Runner::run_command( <<-EOF
        cat<<END>#{datafile}
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
  # NOTE: handy feature called 'anchors' explained in https://learnxinyminutes.com/docs/yaml/
  # appears to be breaking Ruby's 2.1.9p490 YAML processor
  # keep here for exploring with newer releases
  context 'YAML with anchors' do
    datafile = '/tmp/beoken.yaml'
    before(:each) do
      # NOTE: indent and white space matters
      Specinfra::Runner::run_command( <<-EOF
        cat<<END>#{datafile}
---
dc: &dc
  datacenter: 'miami'
node: &node
  : << *dc
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
      # /uru/ruby/lib/ruby/2.1.0/psych.rb:370:in `parse': (<unknown>):
      # did not find expected key while parsing a block mapping at line 5 column 3 (Psych::SyntaxError)
      # TODO: yamllint (easier outside uru sandbox)
    end
  end
end