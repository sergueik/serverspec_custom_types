if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end

# In the default Puppet MSI install, neither the ruby-augeas bindings nor augeas native libraries are provided,
# therefore the provider is not suitable out of the box
# one is advised to compile augeas for windows and install the ruby-augeas gem oneself
# https://tickets.puppetlabs.com/browse/PA-1163 is still open|unresolved
# the augtool availability for windows is still uncertain
# https://github.com/MikaelSmith/augeas/tree/windows

# vanilla tomcat application comes out of the box with welcome pages in $env:{CATALINA_HOME}/webapps/ROOT and is testable through
# http://localhost:8080/index.jsp
# but the enterprise version is likely locked from displaying static content

# https://www.moreofless.co.uk/static-content-web-pages-images-tomcat-outside-war/
# tomcat allows simple configuration
# the <Context docBase="c:/temp" path="/static"/>
# for directory listing see
# https://webmasters.stackexchange.com/questions/37855/tomcat-serving-static-content-with-directory-listings

context 'Tomcat static page test' do

  service_name = 'Tomcat85'
  catalina_home = 'c:/java/tomcat 8.5'
  static_page_path = '/static'
  static_page_doc_base = 'c:/temp'
  static_page = 'index.html'
  server_xml_file = "#{catalina_home}/conf/server.xml"
  static_page_datafile = "#{static_page_path}/#{static_page}"
  static_page_content = <<-EOF
<!DOCTYPE html>
  <html>
    <head>
    </head>
    <body>
    </body>
  </html>
EOF
  # NOTE: cannot before(:all)
  #   undefined method `metadata' for nil:NilClass

  before(:each) do

    tmp1 = static_page_content.gsub(/\$/, '\\$')
    tmp2 = tmp1.gsub(/\r?\n/, ' ')
    static_page_content = tmp2
    $stderr.puts "Writing #{static_page_datafile}"
    $stderr.puts "Preparing #{static_page_content}"
    Specinfra::Runner::run_command( <<-EOF
      # no space at beginning of the document is critical for xml
      out-file -filepath '#{static_page_datafile}' -encoding ASCII -inputObject '#{static_page_content}'
    EOF
    )
    Specinfra::Runner::run_command( <<-EOF
      $service_name =  '#{service_name}'
      $catalina_home = '#{catalina_home}'
      $static_page_path = '#{static_page_path}'
      $static_page_doc_base = '#{static_page_doc_base}'
      stop-service -name $service_name
      $server_xml_file = resolve-path "#{server_xml_file}"
      $xml = new-object 'System.Xml.XmlDocument'
      $xml.Load($server_xml_file)
      # NOTE:  would mistakenly find commented nodes
      $child = $xml.SelectSingleNode('//Server/Service/Engine/Host[@name="localhost"]/Context')
      write-output $child
      if ($child -eq $null) {
        $child = $xml.CreateElement('Context')
        $child.SetAttribute('path', $static_page_path)
        $child.SetAttribute('docBase', $static_page_doc_base )
        $parent = @($xml.SelectSingleNode('//Server/Service/Engine/Host[@name="localhost"]'))[0]
        $parent.AppendChild($child) | out-null
      } else {
        $child.SetAttribute('path', $static_page_path)
        $child.SetAttribute('docBase', $static_page_doc_base )
      }
      $xml.save($server_xml_file)
      if ($debug) {
        write-debug $xml.OuterXml
      }
      start-service -name $service_name
      # invalid path:
      # java.util.concurrent.ExecutionException: org.apache.catalina.LifecycleException: Failed to start component [StandardEngine[Catalina].StandardHost[localhost].StandardContext[/static]]
      # non-unique DOM node
    EOF
    )
  end
    describe command(<<-EOF
    $response = Invoke-WebRequest -uri http://localhost:8080/static/#{static_page}
    write-output ('Status: ' + $response.StatusCode)
    format-list -inputObject $response.Headers
  EOF
  ) do
    its(:stdout) { should contain 'Status: 200' }
    its(:stdout) { should contain 'Key   : Content-Type' }
    its(:stdout) { should contain 'Value : text/html' }
    # its(:stderr) { should contain 'Waiting for service' }
    # <Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><S S="warning">Waiting for service 'Apache Tomcat 8.5 Tomcat85 (Tomcat85)' to stop...</S><S S="warning">Waiting for service 'Apache Tomcat 8.5 Tomcat85 (Tomcat85)' to stop...</S></Objs>

  end
end

