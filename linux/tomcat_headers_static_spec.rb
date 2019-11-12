require 'spec_helper'


# vanilla tomcat application comes out of the box with static welcome pages in $CATALINA_HOME/webapps/ROOT and is testable through
# http://localhost:8080/index.jsp
# but one is likely observe the enterprise version locked from displaying static content

# https://www.moreofless.co.uk/static-content-web-pages-images-tomcat-outside-war/
# tomcat allows simple configuration
# the <Context docBase="/var/static" path="/static" />
# for directory listing see
# https://webmasters.stackexchange.com/questions/37855/tomcat-serving-static-content-with-directory-listings

context 'Tomcat static page test' do

  puppet_home = '/opt/puppetlabs/puppet/bin'
  catalina_home = '/opt/tomcat'
  static_page_path = '/var/static'
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
  before(:each) do
    $stderr.puts "Writing #{static_page_datafile}"
    Specinfra::Runner::run_command( <<-EOF
      mkdir -p $(dirname #{static_page_datafile})
      # no space at beginning of the document is critical for xml
      cat<<DATA|sed 's|^\\s\\s*||' | tee #{static_page_datafile}
        #{static_page_content.strip}
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
    set /augeas/load/xml/incl "#{server_xml_file}"
    load
    insert 'Context' after '/files#{server_xml_file}/Server/Service/Engine/Host[#attribute/name="localhost"]/Valve'
    save
    set '/files#{server_xml_file}/Server/Service/Engine/Host[#attribute/name="localhost"]/Context/#attribute/path' '/static'
    set '/files#{server_xml_file}/Server/Service/Engine/Host[#attribute/name="localhost"]/Context/#attribute/docBase' '/var/static'
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
    let(:path) { "/bin:/usr/bin:/sbin:#{puppet_home}"}
    its(:stdout) { should match '.*#attribute/name = "localhost"' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end

  describe command(<<-EOF
    #{catalina_home}/bin/shutdown.sh
    #{catalina_home}/bin/startup.sh
    sleep 30
    curl -k -I http://localhost:8080/static/#{static_page}
  EOF
  ) do
    its(:stdout) { should contain 'X-Frame-Options: SAMEORIGIN' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }

  end
end
context 'Security Headers' do
  puppet_home = '/opt/puppetlabs/puppet/bin'
  catalina_home = '/opt/tomcat'
  web_xml = "#{catalina_home}/conf/web.xml"
  aug_script = '/tmp/example.aug'  program=<<-EOF

set '/augeas/load/xml/lens' 'Xml.lns'
set '/augeas/load/xml/incl' '#{web_xml}'
load
# Arbirtarily places the new config close to an end ot web-app
# NOTE: assumes the session-config is present
insert 'filter' before '/files#{web_xml}/web-app/session-config/session-timeout[#text="30"][parent::*]'
# a safer place would be above the mime mapping group
# insert 'filter' before '/files#{web_xml}/web-app/mime-mapping[1]'
# NOTE: assumes there is only one "/web-app/filter" node.
# # protect against "too many matches for path expression" augeas error when dulicate nodes are found in the XML
set '/files#{web_xml}/web-app/filter[last()]/filter-name/#text' 'httpHeaderSecurity'
set '/files#{web_xml}/web-app/filter[last()]/filter-class/#text' 'org.apache.catalina.filters.HttpHeaderSecurityFilter'
set '/files#{web_xml}/web-app/filter[last()]/async-supported/#text' 'true'
save
print '/files#{web_xml}//web-app/filter[last()]'

insert 'filter-mapping' before '/files#{web_xml}/web-app/session-config'

set '/files#{web_xml}/web-app/filter-mapping[last()]/filter-name/#text' 'httpHeaderSecurity'
set '/files#{web_xml}/web-app/filter-mapping[last()]/url-pattern/#text' '/*'
set '/files#{web_xml}/web-app/filter-mapping[last()]/dispatcher/#text' 'REQUEST'
save
print '/files#{web_xml}/web-app/filter-mapping[last()]'

insert 'init-param' after '/files#{web_xml}/web-app/filter/async-supported'

# write the children of /web-app/filter/init-param'
set '/files#{web_xml}/web-app/filter[last()]/init-param[1]/param-name/#text' 'antiClickJackingEnabled'
set '/files#{web_xml}/web-app/filter[last()]/init-param[1]/param-value/#text' 'true'
insert 'init-param' after '/files#{web_xml}/web-app/filter/async-supported'
set '/files#{web_xml}/web-app/filter[last()]/init-param[1]/param-name/#text' 'antiClickJackingOption'
set '/files#{web_xml}/web-app/filter[last()]/init-param[1]/param-value/#text' 'SAMEORIGIN'
save
print '/files#{web_xml}/web-app/filter[last()]'
# finally print errors
print '/augeas/error'

  EOF
  describe command(<<-EOF
    echo '#{program}' > #{aug_script}
    augtool -f #{aug_script}
  EOF
  ) do
    let(:path) { "/bin:/usr/bin:/sbin:#{puppet_home}"}
    # its(:stdout) { should match '.*#attribute/name = "localhost"' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end

  describe command(<<-EOF
    xmllint --xpath \\
    '/*[local-name()="web-app"]/*[local-name()="filter"]/*[local-name()="filter-name"][text() = "httpHeaderSecurity"]/../*[local-name()="dispatcher"]/text()' \\
    #{web_xml}
  EOF
  ) do
    its(:stdout) { should contain 'REQUEST' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end

    # NOTE: commenting the line containing an undefined variable inside HEREDOC
    # does not suppress NameError exception
    # undefined local variable or method `static_page' for RSpec::ExampleGroups::SecurityHeaders:Class
    # curl -k -I http://localhost:8080/static/#{static_page}
  describe command(<<-EOF
    #{catalina_home}/bin/shutdown.sh
    #{catalina_home}/bin/startup.sh
    sleep 30
    # NOTE: may refuse the specific response headers
    curl -k -I http://localhost:8080/
  EOF
  ) do
    its(:stdout) { should contain 'X-Frame-Options: SAMEORIGIN' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end
end
