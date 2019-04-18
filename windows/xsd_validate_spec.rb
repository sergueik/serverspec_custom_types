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
context 'XSD validation' do
  context 'passing validation test' do
    # origin: https://www.w3schools.com/xml/schema_example.asp
    data_file = 'c:\\windows\\temp\\shiporder.xml'
    data_content = <<-EOF
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
    schema_file = 'c:\\windows\\temp\\shiporder.xsd'
    schema_content = <<-EOF
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
    # NOTE: undefined method `gsub!' for nil:NilClass (NoMethodError)
    # xml_content.gsub!(/\$/, '\\$').gsub!(/\\r?n/, ' ')
    tmp1 = data_content.gsub(/\$/, '\\$')
    tmp2 = tmp1.gsub(/\\r?\\n/, ' ')
    data_content = tmp2
    before(:each) do
      $stderr.puts "Preparing #{data_content}"
      $stderr.puts "Writing #{data_file}"
      Specinfra::Runner::run_command( <<-EOF
        # no space at beginning of the document is critical for xml
        out-file -filepath '#{data_file}' -encoding ASCII -inputObject '#{data_content}'
      EOF
      )
      $stderr.puts "Preparing #{schema_content}"
      $stderr.puts "Writing #{schema_file}"
      Specinfra::Runner::run_command( <<-EOF
        # no space at beginning of the document is critical for xml
        out-file -filepath '#{schema_file}' -encoding ASCII -inputObject @'
#{schema_content}
'@
# the XML declaration must be the first node in the document, and no white space characters are allowed to appear before it.
# White space is not allowed before the string terminator
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

              string schema_file = @"#{schema_file}";

              XmlTextReader schemaReader = new XmlTextReader(schema_file);
              XmlSchema schema = XmlSchema.Read(schemaReader, SchemaValidationHandler);

              xmlDoc.Schemas.Add(schema);

              string data_file = @"#{data_file}";
              xmlDoc.Load(data_file);
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
  context 'failing validation test' do
    # origin: https://www.w3schools.com/xml/schema_example.asp
    data_file = 'c:\\windows\\temp\\bad_shiporder.xml'
    data_content = <<-EOF
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
      <note>Special Edition</note>
      <quantity>1</quantity>
      <price>10.90</price>
      <invalid>Hello World</invalid>
    </item>
    <item>
      <title>Hide your heart</title>
      <quantity>1</quantity>
      <price>9.90</price>
    </item>
  </shiporder>
    EOF
    schema_file = 'c:\\windows\\temp\\shiporder.xsd'
    # the XML declaration must be the first node in the document, and no white space characters are allowed to appear before it.
    schema_content = <<-EOF
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
    # NOTE: undefined method `gsub!' for nil:NilClass (NoMethodError)
    # xml_content.gsub!(/\$/, '\\$').gsub!(/\\r?n/, ' ')
    tmp1 = data_content.gsub(/\$/, '\\$')
    tmp2 = tmp1.gsub(/\\r?\\n/, ' ')
    data_content = tmp2
    before(:each) do
      $stderr.puts "Preparing #{data_content}"
      $stderr.puts "Writing #{data_file}"
      Specinfra::Runner::run_command( <<-EOF
        # no space at beginning of the document is critical for xml
        out-file -filepath '#{data_file}' -encoding ASCII -inputObject '#{data_content}'
      EOF
      )
      $stderr.puts "Preparing #{schema_content}"
      $stderr.puts "Writing #{schema_file}"
      Specinfra::Runner::run_command( <<-EOF
        # no space at beginning of the document is critical for xml
        out-file -filepath '#{schema_file}' -encoding ASCII -inputObject @'
#{schema_content}
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

              string schema_file = @"#{schema_file}";

              XmlTextReader schemaReader = new XmlTextReader(schema_file);
              XmlSchema schema = XmlSchema.Read(schemaReader, SchemaValidationHandler);

              xmlDoc.Schemas.Add(schema);

              string data_file = @"#{data_file}";
              xmlDoc.Load(data_file);
              xmlDoc.Validate(DocumentValidationHandler);
              Console.WriteLine("Success");
          }

          private static void SchemaValidationHandler(object sender, ValidationEventArgs e)
          {
              System.Console.Error.WriteLine("SCHEMA VALIDATION ERROR: " + e.Message);
          }

          private static void DocumentValidationHandler(object sender, ValidationEventArgs e)
          {
              System.Console.Error.WriteLine("DOCUMENT VALIDATION ERROR: " + e.Message);
          }
      }
  }
'@  -ReferencedAssemblies 'System.dll','System.Data.dll','Microsoft.CSharp.dll','System.Xml.Linq.dll','System.Xml.dll','System.Xml.ReaderWriter.dll','System.Xml.dll'

  $status = [ValidationTests.Program]::Main(@())

    EOF
    ) do
      its(:stdout) { should match 'Success' }
      # will print: The element 'item' has invalid child element 'note'
      its(:stderr) { should be_empty }
    end
  end
end