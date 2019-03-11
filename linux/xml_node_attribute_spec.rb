require 'spec_helper'
require 'rexml/document'

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

context 'XML attribute names spec' do
  license_datafile = '/tmp/license.xml'
  license_content = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
  <key-list>
  <key options="options" usage-limit="data" expiration-date="data"
  licence-model="server" customer="customer name">
  ZHVtbXkgZGF0YQo=
  </key>
  <!-- dummy data -->
  </key-list>
  EOF
  before(:each) do
    $stderr.puts "Writing #{license_datafile}"
    file = File.open(license_datafile, 'w')
    file.puts license_content
    file.close
  end
  context 'xmllint command' do
    # NOTE: the following fails to compile:
    # xmllint --xpath '//*:name()' /tmp/license.xml
    # XPath error : Invalid expression //*:name()
    # the following fils to iterate over attbibutes beyond the first attribute
    # xmllint --xpath 'name(//*/@*)' /tmp/license.xml

    describe command(<<-EOF
      xmllint --xpath '//@*' '#{license_datafile}' | sed 's|"[^"]*"|"..."\\n|g'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      %w|
        options
        usage-limit
        expiration-date
        licence-model
        customer
      |.each do|attribute_name|
        its(:stdout) { should include "#{attribute_name}=\"...\"" }
      end
    end
  end
  context 'xsltproc command' do
    attribute_extract_datafile = '/tmp/attr_printer.xml'
    attribute_extract_content = <<-EOF
<?xml version="1.0"?>
      <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
        <xsl:template match="/">
          <xsl:apply-templates select="//@*" />
        </xsl:template>
        <xsl:template match="//@*">
           <xsl:value-of select="name()"/>
           <xsl:text>&#xa;</xsl:text>
        </xsl:template>
      </xsl:stylesheet>
    EOF
    # https://www.w3.org/TR/xpath-functions/#func-name
    before(:each) do
      $stderr.puts "Writing #{attribute_extract_datafile}"
      file = File.open(attribute_extract_datafile, 'w')
      file.puts attribute_extract_content
      file.close
    end
    describe command(<<-EOF
      xsltproc '#{attribute_extract_datafile}' '#{license_datafile}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      %w|
        options
        usage-limit
        expiration-date
        licence-model
        customer
      |.each do|attribute_name|
        its(:stdout) { should include attribute_name }
      end
    end
  end
end