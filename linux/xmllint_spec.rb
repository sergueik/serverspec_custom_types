require 'spec_helper'
require 'rexml/document'
include REXML

context 'xmllint' do
  # this example uses stock tomcat configuration for some extraction
  # https://www.digitalocean.com/community/tutorials/how-to-install-apache-tomcat-7-on-centos-7-via-yum
  catalina_home = '/usr/share/tomcat'
  server_xml = "#{catalina_home}/conf/server.xml"
  web_xml = "#{catalina_home}/conf/web.xml"

  context 'availability' do
    describe command('which xmllint') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new('/bin/xmllint', Regexp::IGNORECASE) }
      its(:stderr) { should be_empty }
    end
  end
  context 'Tomcat web.xml configuration' do
    # NOTE: the web.xml is using namespaces
    describe command(<<-EOF
      xmllint --xpath "//*[local-name()='servlet']/*[local-name()='servlet-class']/text()" #{web_xml}
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      [
        'org.apache.catalina.servlets.DefaultServlet',
        'org.apache.jasper.servlet.JspServlet'
      ].each do |servlet_class_name|
        its(:stdout) { should match Regexp.new(servlet_class_name, Regexp::IGNORECASE) }
      end
      its(:stderr) { should be_empty }
    end
    # somewhat better formatting
    # based on: https://stackoverflow.com/questions/16959908/native-shell-command-set-to-extract-node-value-from-xml
    # note the specifics of using the quotes
    # around the command but not around the XPath

    web_xml_data = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd" version="3.1">
        <filter>
        <filter-name>httpHeaderSecurity</filter-name>
        <filter-class>org.apache.catalina.filters.HttpHeaderSecurityFilter</filter-class>
        <async-supported>true</async-supported>
        </filter>
        <filter>
        <filter-name>setCharacterEncodingFilter</filter-name>
        <filter-class>org.apache.catalina.filters.SetCharacterEncodingFilter</filter-class>
        <init-param>
          <param-name>encoding</param-name>
          <param-value>UTF-8</param-value>
        </init-param>
        <async-supported>true</async-supported>
        </filter>
        <!-- one of commented fragments -->
        <!--
        <filter>
          <filter-name>failedRequestFilter</filter-name>
          <filter-class>
            org.apache.catalina.filters.FailedRequestFilter
          </filter-class>
          <async-supported>true</async-supported>
        </filter>
      -->
      </web-app>
    EOF
    # To make this test pass one has to uncomment a few of 
    # stock cataline configuration <filter> DOM elements
    # or used the inline example above
    filter_name = 'httpHeaderSecurity'
    describe command(<<-EOF
      echo "cat //*[local-name()='filter']/*[local-name()='filter-name']/text()" | xmllint --shell #{web_xml}
      echo "cat //*[local-name()='filter']/*[local-name()='filter-name']/text()" | xmllint --shell #{web_xml}| grep -qi '#{filter_name}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      [
        filter_name,
        'setCharcterEncodingFilter'
      ].each do |filter_name|
        its(:stdout) { should match Regexp.new(filter_name, Regexp::IGNORECASE) }
      end
      [
        'failedRequestFilter'
      ].each do |filter_name|
        its(:stdout) { should_not match Regexp.new(filter_name, Regexp::IGNORECASE) }
      end
      its(:stderr) { should be_empty }
      its(:exit_status) { should eq 0 }
    end
    describe command(<<-EOF
      echo "cat \\"//*[local-name()='filter']/*[local-name()='filter-name']/text()\\"" | xmllint --shell #{web_xml}
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      [
        'XPath error : Invalid predicate',
        'evaluation failed',
        'no such node',
      ].each do |error_message|
        its(:stderr) { should contain error_message }
      end
    end
    # sibling node locator, reading the XML from STDIN, like from another process output
    servlet_class_name = 'org.apache.catalina.servlets.DefaultServlet'
    describe command(<<-EOF
      SERVLET_CLASS_NAME='#{servlet_class_name}'
      WEB_XML='#{web_xml}'
      xmllint --xpath "//*[local-name()='servlet-class' and contains(text(),'${SERVLET_CLASS_NAME}')]" - < "${WEB_XML}"
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new(servlet_class_name, Regexp::IGNORECASE) }
      # RSpec 3.x syntax:
      its(:stdout) { is_expected.to match Regexp.new(servlet_class_name, Regexp::IGNORECASE) }
      its(:stderr) { should be_empty }
    end
  end

  context 'Tomcat server.xml configuration' do

    context 'Multi Entry condition' do
      # example  of multi entry command which may be useful as an unless conditon
      # for a Puppet exec resurce performing multiple 'insert' and 'set' into redundnt DOM path like
      # /web-app/filter/init-param/param-name
      # /web-app/filter/init-param/param-value
      # to configure the parameters for constructor injection of class e.g.
      # 'com.apache.catalina.filters.HtpHeaderSecurityFilter'
      entries = %w|
        antiClickJackingOption
        antiClickJackingEnabled
        hstMAxAgeSeconds
      |
      entries_regexp = '(' + ( entries.join '|' ) + ')' # antiClickJackingOption|antiClickJackingEnabled|hstMAxAgeSeconds
      entries_size = entries.size.to_s # 3
      # see also http://xmlsoft.org/tree.html
      describe command(<<-EOF
       test $(xmllint --debug '#{web_xml}' | grep -E 'content=#{entries_regexp}' | wc -l) -eq #{entries_size}
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should be_empty }
        its(:stderr) { should be_empty }
      end
    end

    # simple node attribute value validation
    port = '8443'
    ciphers = [
      'TLS_RSA_WITH_AES_128_CBC_SHA',
      'TLS_RSA_WITH_AES_128_CBC_SHA256',
      'TLS_RSA_WITH_AES_128_GCM_SHA256',
      'TLS_RSA_WITH_AES_256_CBC_SHA',
      'TLS_RSA_WITH_AES_256_CBC_SHA256',
      'TLS_RSA_WITH_AES_256_GCM_SHA384'
    ]
    describe command(<<-EOF
      xmllint --xpath "/Server/Service/Connector[@port='#{port}']/@ciphers" #{server_xml}
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new('ciphers="' + ciphers.join(', ') + '"', Regexp::IGNORECASE) }
      its(:stderr) { should be_empty }
    end
  end
  context 'Jetty configuration' do
    # querying DOM node set
    jetty_home = '/openidm'
    jetty_xml = "#{jetty_home}/conf/jetty.xml"
    ciphers = [
      'TLS_RSA_WITH_AES_128_CBC_SHA',
      'TLS_RSA_WITH_AES_128_CBC_SHA256',
      'TLS_RSA_WITH_AES_128_GCM_SHA256',
      'TLS_RSA_WITH_AES_256_CBC_SHA',
      'TLS_RSA_WITH_AES_256_CBC_SHA256',
      'TLS_RSA_WITH_AES_256_GCM_SHA384'
    ]
    describe command(<<-EOF
      xmllint --xpath "/Configure/New[@id='sslContextFactory']/Set[@name='IncludeCipherSuites']/Array/Item" #{jetty_xml}
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new(ciphers.map{ |cipher| "<Item>#{cipher}</Item>" }.join(''), Regexp::IGNORECASE) }
      its(:stderr) { should be_empty }
    end
  end
  context 'HTML attribute validation' do
    # https://www.vultr.com/docs/how-to-install-and-configure-graphite-on-centos-7
    graphite_home = '/opt/graphite'
    describe command(<<-EOF
      xmllint --html --xpath \\
      '/html/body//form[@action="/account/login/"]//input[@type="password" or @type = "text"]'  \\
      #{graphite_home}/webapp/graphite/templates/login.html
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new('autocomplete="false"' )}
      its(:stdout) { should_not match 'HTML parser error' }
      its(:stderr) { should be_empty }
    end
  end
  context 'Missing Node Validation' do
    # some Java application are re-condifured by commenting whole nodes in XML configuration e.g.
    # https://docs.oracle.com/javadb/10.10.1.2/adminguide/radminjmxenabledisable.html
    # https://docs.wso2.com/display/ESB470/Default+Ports+of+WSO2+Products
    jmx_config = '/usr/share/wso2/apim/application/repository/conf/etc/jmx.xml'
    {
      'RMIRegistry' => 11111,
      'RMIServer' => 9999,
    }.each do |service, port|
      describe command("xmllint --xpath '//*[local-name()=\"#{service}\"]' '#{jmx_config}'") do
        # the ports will be disabled in the sut configuration. Node made invisible.
        # the alterantive way (not shown here) is to set RMIStartService text to false
        its(:stderr) { should match /XPath set is empty/ }
      end
      describe port(port) do
        it { should_not be_listening }
      end
    end
  end
end
