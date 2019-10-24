require 'spec_helper'
require 'json'
require 'fileutils'

context 'Missing Element' do
  config_home = '/tmp'
  config_json = "#{config_home}/config.json"
  data = {
    :simple_key => 'value' ,
    :array_key => %w|value1 value2 value3|
  }
  before(:each) do
    $stderr.puts "Writing #{config_json}"
    file = File.open(config_json, 'w')
    file.puts JSON.generate(  data )
    file.close
  end

  describe command(<<-EOF
    jq '.missing_element' '#{config_json}'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'null' }
  end
  describe command(<<-EOF
    jq '.missing_element' '#{config_json}' | grep -q 'null' && echo 'MARKER'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'MARKER' }
  end
end
