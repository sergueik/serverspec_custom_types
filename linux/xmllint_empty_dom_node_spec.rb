require 'spec_helper'

context 'Bad Constructor Argument Match' do

  # tomcat default yum install
  catalina_home = '/opt/tomcat'
  aug_script = "/tmp/example-#{Process.pid}.au"
  server_config_file = "#{catalina_home}/conf/server.xml"
  web_xml = "#{catalina_home}/conf/web.xml"

  # http://augeas.net/docs/references/lenses/files/tests/test_xml-aug.html#Test_Xml.Xml.empty_element
  # this loosely works:
  # augtool> match /files/tmp/a.xml//init-param[#text]
  # augtool> /files/tmp/a.xml/web/servlet/init-param[1] = (none)
  # augtool> /files/tmp/a.xml/web/servlet/init-param[3] = (none)
  # augtool> # note the gap
  # augtool> match /files/tmp/a.xml/init-param[2][#text]
  # augtool>  (no matches)
  # see also: https://www.baeldung.com/spring-dependency-injection
  # DevOps tools like Puppet are prone to corrupt this
  # based on https://unix.stackexchange.com/questions/430487/identify-empty-xml-files
  context 'bad configuration' do
    describe command(<<-EOF
     DUMMY_BAD_XML_FILE='/tmp/a.xml'
     # NOTE: XML declaration allowed only at the start of the document
     cat <<DATA>$DUMMY_BAD_XML_FILE
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
     xmllint --xpath '//init-param[not(normalize-space())]' $DUMMY_BAD_XML_FILE
    EOF
    ) do
      # let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
      its(:stdout) { should match Regexp.new(Regexp.escape('<init-param/>')) }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'good configuration' do
    describe command(<<-EOF
     DUMMY_GOOD_XML_FILE='/tmp/b.xml'
     # NOTE: XML declaration allowed only at the start of the document
     cat <<DATA>$DUMMY_GOOD_XML_FILE
<?xml version="1.0" encoding="UTF-8"?>
  <web>
    <servlet>
      <servlet-name>default</servlet-name>
      <servlet-class>org.apache.catalina.servlets.DefaultServlet</servlet-class>
      <init-param>
        <param-name>debug</param-name>
        <param-value>0</param-value>
      </init-param>
      <init-param>
        <param-name>listings</param-name>
        <param-value>false</param-value>
      </init-param>
      <load-on-startup>1</load-on-startup>
    </servlet>
  </web>
DATA
     xmllint --xpath '//init-param[not(normalize-space())]' $DUMMY_GOOD_XML_FILE
     WEB_XML_FILE='#{web_xml}'
     if [ -f "${WEB_XML_FILE}" ] ; then
       xmllint --xpath '//init-param[not(normalize-space())]' $WEB_XML_FILE
     fi
    EOF
    ) do
      its(:stdout) { should be_empty  }
      # NOTE: undefined method `matches?' for "...":String
      its(:stderr) { should match /XPath set is empty/ }
      its(:stderr) { should contain 'XPath set is empty' }
      its(:exit_status) { should eq 0 }
    end
  end
  context 'original configuration' do
    describe command(<<-EOF
     WEB_XML_FILE='#{web_xml}'
     if [ -f "${WEB_XML_FILE}" ] ; then
       xmllint --xpath '//init-param[not(normalize-space())]' $WEB_XML_FILE
     fi
    EOF
    ) do
      # these expectations will fail or report false positive in the absence of tomcat installation
      # its(:stdout) { should be_empty  }
      # its(:stderr) { should match /XPath set is empty/ }
      # its(:exit_status) { should eq 0 }
    end
  end
end
