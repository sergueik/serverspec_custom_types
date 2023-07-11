if File.exists?( 'spec/windows_spec_helper.rb')
# Copyright (c) Serguei Kouzmine
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'Augeas Removal of DOM Nodes' do

  # default yum install
  catalina_home = '/usr/share/tomcat'
  catalina_conf = "#{catalina_home}/conf"
  catalina_conf = '/tmp'
  xml_file = "#{catalina_conf}/web.xml"
  xml_data = <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd" version="3.1">
      <filter>
        <filter-name>httpHeaderSecurity</filter-name>
        <filter-class>org.apache.catalina.filters.HttpHeaderSecurityFilter</filter-class>
        <async-supported>true</async-supported>
      </filter>
      <!--
        <filter>
          <filter-name>setCharacterEncodingFilter</filter-name>
          <filter-class>org.apache.catalina.filters.SetCharacterEncodingFilter</filter-class>
          <init-param>
            <param-name>encoding</param-name>
            <param-value>UTF-8</param-value>
          </init-param>
          <async-supported>true</async-supported>
        </filter>
      -->
    <filter>
      <filter-name>failedRequestFilter</filter-name>
      <filter-class>
        org.apache.catalina.filters.FailedRequestFilter
      </filter-class>
      <async-supported>true</async-supported>
    </filter>

    </web-app>
  EOF
  # https://github.com/hercules-team/augeas/wiki/Path-expressions
  remove_filter_name = 'httpHeaderSecurity'
  remaining_filter_name = 'failedRequestFilter'
  script_data = <<-EOF
    set /augeas/load/xml/lens 'Xml.lns'
    set /augeas/load/xml/incl '#{xml_file}'
    load
    print
    rm '/files/#{xml_file}/web-app/filter/filter-name[\#text=~ regexp("#{remove_filter_name}.*")]/..'
    save
    # noisy
    # print '/augeas//error'
    print '/augeas/files#{xml_file}/error'
    quit
  EOF
  script_file = '/tmp/example.aug'
  before(:each) do
    $stderr.puts "Writing #{xml_file}"
    file = File.open(xml_file, 'w')
    file.puts xml_data.strip
    file.close
    $stderr.puts "Writing #{script_file}"
    file = File.open(script_file, 'w')
    file.puts script_data
    file.close
  end
  describe command(<<-EOF
    1>/dev/null 2>/dev/null augtool -A -f '#{script_file}'
    xmllint --xpath '//*[ local-name()="filter-name" and contains(text(),"#{remove_filter_name}") ]' '#{xml_file}'
    xmllint --xpath '//*[ local-name()="filter-name" and contains(text(),"#{remaining_filter_name}") ]/text()' '#{xml_file}'
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:stderr) { should contain 'XPath set is empty'}
    its(:stdout) { should contain remaining_filter_name }
    its(:stdout) { should_not contain remove_filter_name }

  end
end
