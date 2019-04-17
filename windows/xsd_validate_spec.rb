if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end

# require 'spec_helper'

# NOTE: Ruby XML modules are not used by this spec
require 'rexml/document'
begin
  # http://www.w3big.com/ruby/ruby-xml-xslt-xpath.html
  require 'xslt'
rescue LoadError => e
  # cannot load such file -- xslt
end

context 'XSD Run Test' do
  # origin: https://www.w3schools.com/xml/schema_example.asp
  xml_datafile = 'c:\\windows\\temp\\shiporder.xml'
  xml_content = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>

<shiporder orderid="889923" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="shiporder.xsd">
  <orderperson>John Smith</orderperson>
  <shipto>
    <name>Ola Nordmann</name>
    <address>Langgt 23</address>
    <city>4000 Stavanger</city>
    <country>Norway</country>
  </shipto>
  <item>
    <title>Empire Burlesque</title>
    <note>Special Edition</note>
    <quantity>1</quantity>
    <price>10.90</price>
  </item>
  <item>
    <title>Hide your heart</title>
    <quantity>1</quantity>
    <price>9.90</price>
  </item>
</shiporder>
  EOF
  xsd_datafile = 'c:\\windows\\temp\\shiporder.xsd'
  xsd_content = <<-EOF
<?xml version="1.0" encoding="UTF-8" ?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">

<xs:element name="shiporder">
  <xs:complexType>
    <xs:sequence>
      <xs:element name="orderperson" type="xs:string"/>
      <xs:element name="shipto">
        <xs:complexType>
          <xs:sequence>
            <xs:element name="name" type="xs:string"/>
            <xs:element name="address" type="xs:string"/>
            <xs:element name="city" type="xs:string"/>
            <xs:element name="country" type="xs:string"/>
          </xs:sequence>
        </xs:complexType>
      </xs:element>
      <xs:element name="item" maxOccurs="unbounded">
        <xs:complexType>
          <xs:sequence>
            <xs:element name="title" type="xs:string"/>
            <xs:element name="note" type="xs:string" minOccurs="0"/>
            <xs:element name="quantity" type="xs:positiveInteger"/>
            <xs:element name="price" type="xs:decimal"/>
          </xs:sequence>
        </xs:complexType>
      </xs:element>
    </xs:sequence>
    <xs:attribute name="orderid" type="xs:string" use="required"/>
  </xs:complexType>
</xs:element>

</xs:schema>
  EOF
  tmp1 = xml_content.gsub(/\$/, '\\$')
  tmp2 = tmp1.gsub(/\\\\r?\\\\n/, ' ')
  xml_content = tmp2
  $stderr.puts "Preparing #{xml_content}"
  # NOTE: undefined method `gsub!' for nil:NilClass (NoMethodError)
  # xml_content.gsub!(/\$/, '\\$').gsub!(/\\r?n/, ' ')
  # tmp1 = xsd_content.gsub(/\$/, '\\$')
  # tmp2 = tmp1.gsub(/\\\\r?\\\\n/, ' ')
  # xsd_content = tmp2
  $stderr.puts "Preparing #{xsd_content}"
  # NOTE: undefined method `gsub!' for nil:NilClass (NoMethodError)
  # xsd_content.gsub!(/\$/, '\\$').gsub!(/\\r?n/, ' ')
  before(:each) do
    $stderr.puts "Writing #{xml_datafile}"
    Specinfra::Runner::run_command( <<-EOF
      # no space at beginning of the document is critical for xml
      out-file -filepath '#{xml_datafile}' -encoding ASCII -inputObject '#{xml_content}'
    EOF
    )
    $stderr.puts "Writing #{xsd_datafile}"
    Specinfra::Runner::run_command( <<-EOF
      # no space at beginning of the document is critical for xml
      out-file -filepath '#{xsd_datafile}' -encoding ASCII -inputObject @'
#{xsd_content}
'@
    EOF
    )
  end
  # based on: https://gist.github.com/csmoore/604142592047cbaf6f39
  # see also https://github.com/andreburgaud/xvalidatr
  describe command(<<-EOF

  add-type -TypeDefinition @'
using System;
using System.Xml;
using System.Xml.Schema;

namespace ValidationTests
{
    public class Program
    {
        public static void Main(string[] args)
        {
            XmlDocument xmlDoc = new XmlDocument();

            string schemaFile = @"c:\\windows\\temp\\shiporder.xsd";

            XmlTextReader schemaReader = new XmlTextReader(schemaFile);
            XmlSchema schema = XmlSchema.Read(schemaReader, SchemaValidationHandler);

            xmlDoc.Schemas.Add(schema);

            string filename = @"c:\\windows\\temp\\shiporder.xml";
            xmlDoc.Load(filename);
            xmlDoc.Validate(DocumentValidationHandler);
            Console.WriteLine("Success");
        }

        private static void SchemaValidationHandler(object sender, ValidationEventArgs e)
        {
            System.Console.WriteLine(e.Message);
        }

        private static void DocumentValidationHandler(object sender, ValidationEventArgs e)
        {
            System.Console.WriteLine(e.Message);
        }
    }
}
'@  -ReferencedAssemblies 'System.dll','System.Data.dll','Microsoft.CSharp.dll','System.Xml.Linq.dll','System.Xml.dll','System.Xml.ReaderWriter.dll','System.Xml.dll'

$status = [ValidationTests.Program]::Main(@())

  EOF
  ) do
    its(:stdout) { should match 'Success' }
  end
end
