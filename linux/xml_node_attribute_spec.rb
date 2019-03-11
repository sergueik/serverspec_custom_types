require 'spec_helper'
require 'rexml/document'

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

context 'XML attribute names spec' do

  # NOTE: the following fails to compile:
  # xmllint --xpath '//*:name()' /tmp/license.xml
  # XPath error : Invalid expression //*:name()
  # the following fils to iterate over attbibutes beyond the first attribute
  # xmllint --xpath 'name(//*/@*)' /tmp/license.xml
  license_datafile = '/tmp/identity.xml'
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

  describe command(<<-EOF
    xmllint --xpath '//@*' /tmp/license.xml | sed 's|"[^"]*"|"..."\\n|g'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    [
     'options',
     'usage-limit',
     'expiration-date',
     'licence-model',
     'customer'
    ].each do|attribute_name|
      its(:stdout) { should include "#{attribute_name}=\"...\"" }
    end
  end
end