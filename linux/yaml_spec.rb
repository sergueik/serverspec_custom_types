require 'spec_helper'
"# Copyright (c) Serguei Kouzmine"
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
  # Ansible-style collapsing module arguments
  param2: key1=value1 key2=value2
  param3:
    key3: 'value 3'
    key4: value4
  param4: |
     data


END
      EOF
      )
    end
    describe command(<<-EOF
      cat '#{datafile}' | ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' | \\
      jq '.[]| select( .datacenter | contains("miami")) | .param1 | @csv'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new('"\\\\"a\\\\",\\\\"b\\\\",\\\\"c\\\\"', Regexp::IGNORECASE) }
      its(:stderr) { should_not match 'jq: error: syntax error' }
    end

 #     TODO: collect multiple keys
 #     describe command(<<-EOF
 #       cat '#{datafile}' | ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' | \\
 #       jq '.[]| select( .datacenter | contains("miami")) | tee /tmp/$$.json
 #       jq '[] | .param1, .param2' /tmp/$$.json
 #
 #     EOF
 #     ) do
 #       its(:exit_status) { should eq 0 }
 #       its(:stdout) { should match Regexp.new('"\\\\"a\\\\",\\\\"b\\\\",\\\\"c\\\\"', Regexp::IGNORECASE) }
 #       its(:stdout) { should match Regexp.new('key1\\\\=value1', Regexp::IGNORECASE) }
 #       its(:stderr) { should_not match 'jq: error: syntax error' }
 #     end
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
      cat '#{datafile}' | ruby -rpp -ryaml -rjson -e 'y = YAML.load(ARGF); pp y; puts y["node"]["datacenter"]'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should contain 'miami' }
      its(:stderr) { should be_empty }
    end
    # implies gem install --no-rdoc --no-ri yamllint
    describe command(<<-EOF
      yamllint '#{datafile}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      # NOTE: there is two tools named yamllint:
      # Ruby gem package https://github.com/shortdudey123/yamllint
      # installed via gem install yamllint to /usr/local/bin
      # Python script installed through apt-get install yamllint to /usr/bin
      # Only the former prints the conclusion message to the screen
      its(:stdout) { should contain 'YamlLint found no errors' }
      # its(:stderr) { should be_empty }
      # [DEPRECATION] This gem has been renamed to optimist and will no longer be supported. Please switch to optimist as soon as possible.
    end
  end
end

