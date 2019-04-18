require 'spec_helper'


# The vanilla tomcat application comes with welcome pages and is testable through
# http://localhost:8080/index.jsp and also supports 
# the  <Context docBase="/var/static" path="/static" /> 
# configuration suggested in
# https://www.moreofless.co.uk/static-content-web-pages-images-tomcat-outside-war/
# https://webmasters.stackexchange.com/questions/37855/tomcat-serving-static-content-with-directory-listings
# but the enterprise version could be locked
# 

context 'Tomcat static page test' do

  catalina_home = '/opt/tomcat'
  static_page_path = '/var/static'
  static_page = 'index.html'
  xml_file = "#{catalina_home}/conf/server.xml"
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
   before(:each) do
    $stderr.puts "Writing #{static_page_datafile}"
    Specinfra::Runner::run_command( <<-EOF
      mkdir -p $(dirname #{static_page_datafile})
      # no space at beginning of the document is critical for xml
      cat<<DATA1|tee #{static_page_datafile}
#{static_page_content}
DATA1
    EOF
    )
  end
  def tomcat_version_command_output
    # NOTE: move into the def scope from the top, or not visible
    command("java -cp #{catalina_home}/lib/catalina.jar org.apache.catalina.util.ServerInfo").stdout
  end
  aug_script = '/tmp/example.aug'
  aug_path = "Server/Service/Engine/Host[#attribute/name=\"localhost\"]/#attribute/name"
  program=<<-EOF
    set /augeas/load/xml/lens "Xml.lns"
    set /augeas/load/xml/incl "#{xml_file}"
    load
    insert 'Context' after '/files/opt/tomcat/conf/server.xml/Server/Service/Engine/Host[#attribute/name="localhost"]/Valve'
    save
    set '/files/opt/tomcat/conf/server.xml/Server/Service/Engine/Host[#attribute/name="localhost"]/Context/#attribute/path' '/static'
    set '/files/opt/tomcat/conf/server.xml/Server/Service/Engine/Host[#attribute/name="localhost"]/Context/#attribute/docBase' '/var/static'
    save
  EOF
    # curl -I -k http://localhost:8080/index.jsp
    # HTTP/1.1 200
    # X-Frame-Options: DENY
    # X-Content-Type-Options: nosniff
    # X-XSS-Protection: 1; mode=block
    # Content-Type: text/html;charset=UTF-8

    # HTTP/1.1 404
    # X-Frame-Options: SAMEORIGIN
    # X-Content-Type-Options: nosniff
    # X-XSS-Protection: 1; mode=block
    # Content-Type: text/html;charset=utf-8

    # HTTP/1.1 200
    # X-Frame-Options: SAMEORIGIN
    # X-Content-Type-Options: nosniff
    # X-XSS-Protection: 1; mode=block
    # Accept-Ranges: bytes
    # ETag: W/"62-1555625608000"
    # 
  describe command(<<-EOF
    echo '#{program}' > #{aug_script}
    augtool -f #{aug_script}
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:stdout) { should match '.*#attribute/name = "localhost"' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end
  
  describe command(<<-EOF
    /opt/tomcat/bin/shutdown.sh
    /opt/tomcat/bin/shutdown.sh
    sleep 30
    curl -k -I http://localhost:8080/static/#{static_page}   
  EOF
  ) do
    its(:stdout) { should contain 'X-Frame-Options: SAMEORIGIN' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }

    # curl -I -k http://localhost:8080/index.jsp

  end
end

