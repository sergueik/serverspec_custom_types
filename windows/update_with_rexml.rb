
require 'rexml/document'
require 'pp'
include REXML

# based on: https://stackoverflow.com/questions/22461942/read-edit-and-save-existing-xml-file-with-rexml

# encoding: utf-8
# to turn on debug, in the Windows powershell console
# $env:DEBUG='yes'

$debug = ENV.fetch('DEBUG', '')
$debug = ($debug =~ (/^(true|t|yes|y|1)$/i))
# puts $debug.to_s 0 


$doc = Document.new File.open('web.xml')

# https://www.developer.com/lang/rubyrails/article.php/12159_3672621_2/REXML-Proccessing-XML-in-Ruby.htm
firstmodel = XPath.first( $doc, '//filter/filter-name[text()=="httpHeaderSecurity"]' )
if $debug
  $stderr.puts ('DOM node ' + ( firstmodel.nil? ? 'will be added' : 'already exists'))
end
if $debug
# adding:
#    <filter>
#        <filter-name>httpHeaderSecurity</filter-name>
#        <filter-class>org.apache.catalina.filters.HttpHeaderSecurityFilter</filter-class>
#        <async-supported>true</async-supported>
#    </filter>
end
if firstmodel.nil?
  o = Element.new('filter')
  o.add_element 'filter-name'
  o.elements['filter-name'].text = 'httpHeaderSecurity'
  o.add_element 'filter-class'
  o.elements['filter-class'].text = 'org.apache.catalina.filters.HttpHeaderSecurityFilter'
  o.add_element 'async-supported'
  o.elements['async-supported'].text = 'true'
  $doc.root.add_element o
  $doc.write(File.open('web.xml','w'), 2)
end