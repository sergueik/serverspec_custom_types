if File.exists?( 'spec/windows_spec_helper.rb')
# Copyright (c) Serguei Kouzmine
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'SAX HTML tests' do
  catalina_home = '/opt/tomcat'
  path_separator = ':'
  # xerces, xalan and their dependencies are de facto ord-time standard XML processors
  # jackson is a JSON  and YAML de facto standard processor
  # snakeyaml is its dependency (jackson itself is unnecessarily generic for the here task
  # all these jars are likely be present in tomcat lib directory for apps deployed in tomcat container
  # in 'lib' or some flexible path under the app directory for a standalone springboot app
  app_name = '<application>'
  jar_path = "#{catalina_home}/webapps/#{app_name}/WEB-INF/lib/"
  app_base_path = "/opt/#{app_name}/snandalone/lib"
  jar_path = "#{app_base_path}/lib"
  jar_path = '/tmp'
  jar_versions = {
    'xercesImpl' => '2.10.0',
    'xalan'      => '2.7.2',
    'xml-apis'   => '1.4.01',
    'serializer' => '2.7.2',
    'snakeyaml'  => '1.13'
  }

  jar_versions = {
    'xercesImpl' => '2.12.0',
    'xalan'      => '2.7.2',
    'xml-apis'   => '1.4.01',
    'serializer' => '2.7.2',
    'snakeyaml'  => '1.24'
  }
  jar_search_string = '(' + jar_versions.keys.join('|') + ')'
  # find . -iname '*jar' | grep -iE #{jar_search_string}
  # find . -iname '*jar' | grep -iE '(xercesimpl|xalan|xml-apis|serializer|snakeyaml)'
  # will likely reveal a consistent set of the needed jars
  jars = jar_versions.each do |artifactid,version|
    artifactid + '-' + version + 'jar'
  end
  jars = ['xercesImpl-2.12.0.jar', 'xalan-2.7.2.jar', 'xml-apis-1.4.01.jar', 'serializer-2.7.2.jar', 'snakeyaml-1.24.jar']
  jars_cp = jars.collect{|jar| "#{jar_path}/#{jar}"}.join(path_separator)
  tmp_path = '/tmp'
  yaml_file = "#{tmp_path}/group.yaml"

  # NOTE: indent sensitive
  yaml_data = <<-EOF
---
  - artist:
    id: 001
    name: john
    plays: guitar
  - artist:
    id: 002
    name: ringo
    plays: drums
  - artist:
    id: 003
    name: paul
    plays: vocals
  - artist:
    id: 004
    name: george
    plays: guitar
  EOF
  class_name = 'TestHTMLReport'
  report = 'report.html'
  xpath = '/html/body/table/tr/td'
  source_file = "#{tmp_path}/#{class_name}.java"
  source_data = <<-EOF
    // https://docs.oracle.com/javase/7/docs/api/javax/xml/parsers/SAXParserFactory.html
    // https://mvnrepository.com/artifact/xerces/xerces/2.4.0
    // https://stackoverflow.com/questions/5936003/write-html-file-using-java
    // https://www.programcreek.com/java-api-examples/?class=javax.xml.transform.sax.SAXTransformerFactory&method=setAttribute
    // https://www.programcreek.com/java-api-examples/javax.xml.transform.sax.TransformerHandler

    import java.io.File;
    import java.io.FileOutputStream;
    import java.io.IOException;
    import java.io.InputStream;
    import java.io.OutputStreamWriter;
    import java.nio.file.Files;

    import java.nio.file.Paths;

    import java.util.ArrayList;
    import java.util.Arrays;
    import java.util.Collections;
    import java.util.LinkedHashMap;
    import java.util.Map;

    import javax.xml.transform.OutputKeys;
    import javax.xml.transform.Transformer;
    import javax.xml.transform.TransformerConfigurationException;
    import javax.xml.transform.TransformerFactory;
    import javax.xml.transform.sax.SAXTransformerFactory;
    import javax.xml.transform.sax.TransformerHandler;
    import javax.xml.transform.stream.StreamResult;

    import org.xml.sax.SAXException;
    import org.xml.sax.helpers.AttributesImpl;

    import org.yaml.snakeyaml.Yaml;

    public class #{class_name} {

      public static void main(String[] argv) throws Exception {
        String fileName = "#{yaml_file}";

        String encoding = "UTF-8";
        try {
          FileOutputStream fos = new FileOutputStream("#{report}");
          OutputStreamWriter writer = new OutputStreamWriter(fos, encoding);
          StreamResult streamResult = new StreamResult(writer);

          SAXTransformerFactory saxFactory = (SAXTransformerFactory) TransformerFactory
              .newInstance();
          TransformerHandler transformerHandler = saxFactory
              .newTransformerHandler();
          transformerHandler.setResult(streamResult);

          Transformer transformer = transformerHandler.getTransformer();
          transformer.setOutputProperty(OutputKeys.METHOD, "html");
          // <META http-equiv="Content-Type" content="text/html; charset=UTF-8"> is confusing xmllint
          // transformer.setOutputProperty(OutputKeys.ENCODING, encoding);
          transformer.setOutputProperty(OutputKeys.INDENT, "yes");

          // <!DOCTYPE html> or <!doctype html> is confusing xmllint
          // writer.write("<!DOCTYPE html>\\n");
          writer.flush();
          transformerHandler.startDocument();

          String newline = System.getProperty("line.separator");
          if (newline == null) {
            newline = "\\n"; // unix formatting
          }
          transformerHandler.startElement("", "", "html", new AttributesImpl());
          transformerHandler.startElement("", "", "head", new AttributesImpl());
          transformerHandler.startElement("", "", "title", new AttributesImpl());
          transformerHandler.characters("Group".toCharArray(), 0, 5);
          transformerHandler.endElement("", "", "title");
          transformerHandler.endElement("", "", "head");
          // @formatter:off
          String css = "table, th , td  {\\n" +
            "  font-size: 1em;\\n" +
            "  font-family: Arial, sans-serif;\\n" +
            "  border: 1px solid grey;\\n" +
            "  border-collapse: collapse;\\n" +
            "  padding: 5px;\\n" +
            "} \\n" +
            "table tr:nth-child(odd)	{\\n" +
             "  background-color: #f1f1f1;\\n" +
            "}\\n" +
            "table tr:nth-child(even) {\\n" +
            "  background-color: #ffffff;\\n" +
            "}";
          // @formatter:on
          transformerHandler.startElement("", "", "style", new AttributesImpl());
          transformerHandler.characters(css.toCharArray(), 0, css.length());
          transformerHandler.endElement("", "", "style");
          transformerHandler.startElement("", "", "body", new AttributesImpl());

          // load with snakeyaml
          InputStream in = Files.newInputStream(Paths.get(fileName));
          @SuppressWarnings("unchecked")
          ArrayList<LinkedHashMap<Object, Object>> members = (ArrayList<LinkedHashMap<Object, Object>>) new Yaml()
              .load(in);
          System.out.println(
              String.format("Loaded %d members of the group", members.size()));
          transformerHandler.startElement("", "", "table", new AttributesImpl());
          for (LinkedHashMap<Object, Object> row : members) {
            AttributesImpl attributes = new AttributesImpl();
            attributes.addAttribute("", "", "id", "string",
                row.get("id").toString());
            transformerHandler.startElement("", "", "tr", attributes);
            System.out.println(String.format("Loaded %d propeties of the artist",
                row.keySet().size()));
            for (Object key : row.keySet()) {
              if (row.get(key) != null) {
                transformerHandler.startElement("", "", "td", new AttributesImpl());
                String value = row.get(key).toString();
                transformerHandler.characters(value.toCharArray(), 0,
                    value.length());
                transformerHandler.endElement("", "", "td");
              }
            }
            transformerHandler.endElement("", "", "tr");
          }
          transformerHandler.endElement("", "", "table");
          transformerHandler.endElement("", "", "body");
          transformerHandler.endElement("", "", "html");
          transformerHandler.endDocument();
          writer.close();
        } catch (IOException e) {
          System.err.println("Excption (ignored) " + e.toString());
        } catch (TransformerConfigurationException e) {
          System.err.println("Excption (ignored) " + e.toString());
        } catch (SAXException e) {
          System.err.println("Excption (ignored) " + e.toString());
        }
      }
    }
  EOF
  before(:each) do
    $stderr.puts "Writing #{yaml_file}"
    file = File.open(yaml_file, 'w')
    file.puts yaml_data
    file.close
    $stderr.puts "Writing #{source_file}"
    file = File.open(source_file, 'w')
    file.puts source_data
    file.close
  end
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '#{tmp_path}'
    rm -f "#{report}"
    export CLASSPATH=#{jars_cp}#{path_separator}.
    javac -cp #{jars_cp} '#{source_file}'
    java -cp #{jars_cp}#{path_separator}. '#{class_name}'
    sleep 3
    1>/dev/null 2>/dev/null popd
  EOF

  ) do
    its(:exit_status) { should eq 0 }
    [
      'Loaded 4 members of the group',
      'Loaded 4 propeties of the artist',
    ].each do |line|
      its(:stdout) { should contain line }
    end
    describe file "#{tmp_path}/#{report}" do
      it { should be_file }
    end
    describe command("xmllint --html --xpath '#{xpath}' '#{tmp_path}/#{report}'") do
      its(:exit_status) { should eq 0 }
    end
  end
end
