require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'json'
require 'fileutils'
require 'rexml/document'
include REXML

context 'Missing Element' do
  context 'XML' do
    config_home = '/tmp'
    config_xml = "#{config_home}/config.xml"
    # with more recent Ruby can also use '<<~'
    content = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <web>
        <servlet>
          <init-param>
            <param-name>listings</param-name>
            <param-value>false</param-value>
          </init-param>
          <load-on-startup>1</load-on-startup>
        </servlet>
      </web>
    EOF
    before(:each) do
      $stderr.puts "Writing #{config_xml}"
      file = File.open(config_xml, 'w')
      # remove leading whitespace: XML declaration allowed only at the start of the document
      file.puts content.strip
      # NOTE: will also work
      # content.sub(/^\s+/, '') 
      # content.gsub(/\A[[:space:]]+/, '')
      file.close
    end
    describe command(<<-EOF
      xmllint -xpath '/web/servlet/missing-node' '#{config_xml}' 2>& 1
    EOF
    ) do
      its(:exit_status) { should eq 10 }
      its(:stdout) { should contain 'XPath set is empty' }
    end
    describe command(<<-EOF
      xmllint -xpath '/web/servlet/missing-node' '#{config_xml}' 2>& 1| grep -q 'XPath set is empty' && echo 'MARKER'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should contain 'MARKER' }
    end
  end

  context 'JSON' do
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
end

