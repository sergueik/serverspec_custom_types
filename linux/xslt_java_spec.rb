if File.exists?( 'spec/windows_spec_helper.rb')
"# Copyright (c) Serguei Kouzmine"
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'XSLT tests' do
  tmp_path = '/tmp'
  xslt_file = "#{tmp_path}/transform.xsl"

  # NOTE: indent sensitive
  xslt_data = <<-EOF
    <?xml version="1.0" encoding="utf-8"?>
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xxx="http://xmlns.jcp.org/xml/ns/javaee" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0">
      <xsl:output method="xml" indent="yes"/>
      <xsl:template match="@*|node()">
        <xsl:copy>
          <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
      </xsl:template>
      <xsl:template match="xxx:filter[xxx:filter-name[text()='httpHeaderSecurity']]">
        <xsl:text disable-output-escaping="yes">&lt;!--</xsl:text>
        <xsl:copy-of select="."/>
        <xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
      </xsl:template>
    </xsl:stylesheet>
  EOF
  tmp_path = '/tmp'
  xml_file = "#{tmp_path}/web.xml"
  # replica of real tomcat web.xml with httpHeaderSecurity filter enabled
  xml_data = <<-EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee http://xmlns.jcp.org/xml/ns/javaee/web-app_3_1.xsd" version="3.1">
      <filter>
        <filter-name>httpHeaderSecurity</filter-name>
        <filter-class>org.apache.catalina.filters.HttpHeaderSecurityFilter</filter-class>
        <async-supported>true</async-supported>
      </filter>
      <welcome-file-list>
        <welcome-file>index.html</welcome-file>
        <welcome-file>index.htm</welcome-file>
        <welcome-file>index.jsp</welcome-file>
      </welcome-file-list>
    </web-app>
  EOF
  class_name = 'App'
  source_file = "#{tmp_path}/#{class_name}.java"
  source_data = <<-EOF

    import javax.xml.transform.Source;
    import javax.xml.transform.stream.StreamResult;
    import javax.xml.transform.stream.StreamSource;
    import javax.xml.transform.Transformer;
    import javax.xml.transform.TransformerException;
    import javax.xml.transform.TransformerFactory;

    import java.io.File;
    import java.io.IOException;
    import java.net.URISyntaxException;

    public class #{class_name} {
      public static void main(String[] args) throws IOException, URISyntaxException, TransformerException {
        TransformerFactory factory = TransformerFactory.newInstance();
        Source xslt = new StreamSource(new File(args[1]));
        Transformer transformer = factory.newTransformer(xslt);

        Source text = new StreamSource(new File(args[0]));
        System.err.println(String.format("transforming %s with %s", args[0], args[1]));
        transformer.transform(text, new StreamResult(new File(args[2])));
      }
    }
  EOF
  before(:each) do
    $stderr.puts "Writing #{xslt_file}"
    file = File.open(xslt_file, 'w')
    file.puts xslt_data.strip
    file.close
    $stderr.puts "Writing #{xml_file}"
    file = File.open(xml_file, 'w')
    file.puts xml_data.strip
    file.close
    $stderr.puts "Writing #{source_file}"
    file = File.open(source_file, 'w')
    file.puts source_data
    file.close
  end
  result_file = "#{tmp_path}/result.xml"
  describe command(<<-EOF
    cd '#{tmp_path}'
    rm -f "#{result_file}"
    javac '#{source_file}'
    java '#{class_name}' '#{xml_file}' '#{xslt_file}' '#{result_file}'
    xmllint --xpath '//*[local-name()="filter"]' '#{result_file}'
  EOF

  ) do
      its(:stderr) { should contain 'XPath set is empty'}
  end
end

