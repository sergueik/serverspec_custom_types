require 'spec_helper'

context 'Augeas Match' do

  # default yum install
  catalina_home = '/opt/tomcat'
  aug_script = "/tmp/example-#{Process.pid}.au"
  server_config_file = "#{catalina_home}/conf/server.xml"
  web_xml = "#{catalina_home}/conf/web.xml"

  class_name = 'org.apache.catalina.core.AprLifecycleListener'
  aug_path = "Server/Listener[#attribute/className=\"#{class_name}\"]/#attribute/SSLEngine"
  aug_path_response = '/Server/Listener[2]/#attribute/SSLEngine'
  # inspecting
  # <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  # the augtool match command would print
  # matching nodes in the abbreviated augeas Path notation
  # that resembles DOM XPath
  # https://github.com/hercules-team/augeas/wiki/Path-expressions#Path_Expressions_by_Example
  program=<<-EOF
    # NOTE: no magic meaning of 'o' in the /augeas/load path
    set /augeas/load/o/lens 'Xml.lns'
    set /augeas/load/o/incl '#{server_config_file}'
    # NOTE: leading slash optional ?
    load
    ls /files/opt/tomcat/conf/server.xml/Server/Service[#attribute/name = 'Catalina' ]/
    match /files#{server_config_file}/#{aug_path} 'on'
  EOF
  # http://augeas.net/docs/references/lenses/files/tests/test_xml-aug.html#Test_Xml.Xml.empty_element
  # this loosely works:
  # augtool> match /files/tmp/a.xml//init-param[#text]
  # augtool> /files/tmp/a.xml/web/servlet/init-param[1] = (none)
  # augtool> /files/tmp/a.xml/web/servlet/init-param[3] = (none)
  # augtool> # note the gap
  # augtool> match /files/tmp/a.xml/init-param[2][#text]
  # augtool>  (no matches)

  # based on https://unix.stackexchange.com/questions/430487/identify-empty-xml-files
  describe command(<<-EOF
   DUMMY_XML_FILE='/tmp/a.xml'
   cat <<DATA>$DUMMY_XML_FILE
<?xml version="1.0" encoding="UTF-8"?>
<web>
  <servlet>
    <servlet-name>default</servlet-name>
    <servlet-class>org.apache.catalina.servlets.DefaultServlet</servlet-class>
    <init-param>
      <param-name>debug</param-name>
      <param-value>0</param-value>
    </init-param>
    <!-- bad injector parameter -->
    <init-param/>
    <init-param>
      <param-name>listings</param-name>
      <param-value>false</param-value>
    </init-param>
    <!-- bad injector parameter -->
    <init-param/>
    <load-on-startup>1</load-on-startup>
  </servlet>
</web>
DATA
   xmllint --xpath '//init-param[not(normalize-space())]' $DUMMY_XML_FILE
   xmllint --xpath '//init-param[not(normalize-space())]' #{web_xml}
  EOF
  ) do
    # let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:stdout) { should match Regexp.new(Regexp.escape('<init-param/>')) }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end

  describe command(<<-EOF
    echo '#{program}' > #{aug_script}
    augtool -A -f #{aug_script}
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:stdout) { should match Regexp.escape( "/files#{server_config_file}" + aug_path_response ) }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end

end