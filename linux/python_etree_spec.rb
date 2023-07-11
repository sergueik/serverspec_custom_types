require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'python xm' do
    datafile = '/tmp/pom.xml'
    before(:each) do
      Specinfra::Runner::run_command( <<-EOF
        # XML declaration is allowed only at the start of the document
        cat<<END>'#{datafile}'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>example</groupId>
  <artifactId>basic</artifactId>
  <version>0.4.1-SNAPSHOT</version>
  <packaging>jar</packaging>
  <name>basic</name>
  <description></description>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>1.5.4.RELEASE</version>
    <relativePath/>
  </parent>
  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    <java.version>1.8</java.version>
    <gson.version>2.8.9</gson.version>
  </properties>
</project>
END
      EOF
      )
    end
    # https://www.geeksforgeeks.org/xml-parsing-python/
    # https://docs.python.org/3/library/xml.etree.elementtree.html
    # https://stackoverflow.com/questions/13412496/python-elementtree-module-how-to-ignore-the-namespace-of-xml-files-to-locate-ma
    # in Python 3.8, one can simply use a wildcard ({*}) for the namespace:
    # https://stackoverflow.com/questions/62110439/how-to-use-python-xml-findall-to-find-vimagedata-rid-rid7-otitle-1-ren/62117710#62117710

    scriptfile = "/tmp/process.py"
    data = <<-EOF
import xml.etree.ElementTree as ET
def parseXML(xmlfile):
  # instantiate element tree object
  tree = ET.parse(xmlfile)
  # access root element
  root = tree.getroot()
  # print(root) # dump the attributes
  # print (root.find('parent')) # none - need to prepend child element names with namespaces
  for item in root.findall('{http://maven.apache.org/POM/4.0.0}parent'):
    for child in item.findall('{http://maven.apache.org/POM/4.0.0}version'):
      print(child.text)
  # can to XPath - not limited to immediate children
  for item in root.findall('./{http://maven.apache.org/POM/4.0.0}parent/{http://maven.apache.org/POM/4.0.0}version'):
    print(item.text)
  # this will print many lines of text, from "/dependency/version" nodes in particular
  for item in root.findall('.//{http://maven.apache.org/POM/4.0.0}version'):
    print(item.text)
  # the following only work with Python 3.8
  for item in root.findall('.//{*}version'):
    print(item.text)
if __name__ == '__main__':
   parseXML('#{datafile}')

    EOF
    before(:each) do
      $stderr.puts "Writing #{scriptfile}"
      file = File.open(scriptfile, 'w')
      file.puts data
      file.close
    end

    describe command(<<-EOF
      python #{scriptfile}
    EOF
    ) do
       its(:exit_status) { should eq 0 }
       [
         '1.5.4.RELEASE',
         '0.4.1-SNAPSHOT'
       ].each do |line|
         its(:stdout) { should match Regexp.new(line, Regexp::IGNORECASE) }
       end
       its(:stderr) { should_not match 'Failed to compile' }
  end
end

