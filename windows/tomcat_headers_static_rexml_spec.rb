if File.exists?( 'spec/windows_spec_helper.rb')
# Copyright (c) Serguei Kouzmine
  require_relative '../windows_spec_helper'
end

require 'rexml/document'
require 'pp'
include REXML

$debug = ENV.fetch('DEBUG', '')
$debug = ($debug =~ (/^(true|t|yes|y|1)$/i))
# puts $debug.to_s 0

context 'Tomcat static page test' do

  service_name = 'Tomcat85'
  catalina_home = 'c:/java/tomcat 8.5'
  timeout = 60 # need a long wait for an underpowered VM
  web_xml = "#{catalina_home}/conf/web.xml"
  # NOTE: cannot before(:all)
  #   undefined method `metadata' for nil:NilClass

  before(:each) do

    $doc = Document.new File.open("#{web_xml}")

    # https://www.developer.com/lang/rubyrails/article.php/12159_3672621_2/REXML-Proccessing-XML-in-Ruby.htm
    n = XPath.first( $doc, '//filter/filter-name[text()=="httpHeaderSecurity"]' )
    if $debug
      $stderr.puts ('DOM node ' + ( n.nil? ? 'will be added' : 'already exists'))
    end
    if $debug
    # adding:
    #    <filter>
    #        <filter-name>httpHeaderSecurity</filter-name>
    #        <filter-class>org.apache.catalina.filters.HttpHeaderSecurityFilter</filter-class>
    #        <async-supported>true</async-supported>
    #    </filter>
    end
    if n.nil?
      o = Element.new('filter')
      o.add_element 'filter-name'
      o.elements['filter-name'].text = 'httpHeaderSecurity'
      o.add_element 'filter-class'
      o.elements['filter-class'].text = 'org.apache.catalina.filters.HttpHeaderSecurityFilter'
      o.add_element 'async-supported'
      o.elements['async-supported'].text = 'true'
      $doc.root.add_element o
      $doc.write(File.open("#{web_xml}",'w'), 2)
    end
  end
  describe command(<<-EOF
    $service_name = '#{service_name}'
    $timeout = #{timeout}
    stop-service -name $service_name
    # stop-service : Service 'Apache Tomcat 8.5 Tomcat85 (Tomcat85)' cannot be stopped due to the following error: Cannot open Tomcat85 service on computer '.'
    start-sleep -seconds $timeout
    start-service -name $service_name
    start-sleep -seconds $timeout
    $response = Invoke-WebRequest -uri http://localhost:8080/
    # Invoke-WebRequest : Unable to connect to the remote server WebCmdletWebResponseException
    write-output ('Status: ' + $response.StatusCode)
    format-list -inputObject $response.Headers
  EOF
  ) do
    its(:stdout) { should contain 'Status: 200' }
    its(:stdout) { should contain 'Key   : Content-Type' }
    its(:stdout) { should contain 'Value : text/html' }
    # its(:stderr) { should contain 'Waiting for service' }
    # waiting for service 'Apache Tomcat 8.5 Tomcat85 (Tomcat85)' to stop...

  end
end