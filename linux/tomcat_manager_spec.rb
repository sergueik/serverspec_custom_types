require 'spec_helper'


# vanilla tomcat application comes out of the box with manager in $CATALINA_HOME/webapps/manager
# and is queryable after
# http://localhost:8080/index.jsp
# but the enterprise version is likely move the manager into a different location and
# manager user already configured in node configuration

context 'Tomcat Manager Script test' do
  tomcat_boot_delay = 5
  puppet_home = '/opt/puppetlabs/puppet/bin'
  username = 'user1'
  password = 'password1'
  catalina_home = '/opt/tomcat'
  tomcat_users_xml_file = "#{catalina_home}/conf/tomcat-users.xml"
  tomcat_users_content = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd" version="1.0">
  <role rolename="manager-script"/>
  <user username="#{username}" password="#{password}" roles="manager-script"/>
</tomcat-users>
  EOF
  before(:each) do
    $stderr.puts "Configuring #{tomcat_users_xml_file}"
    Specinfra::Runner::run_command( <<-EOF
      mkdir -p $(dirname #{tomcat_users_xml_file})
      # no space at beginning of the document is critical for xml
      cat<<DATA|tee #{tomcat_users_xml_file}
#{tomcat_users_content}
DATA
    EOF
    )
  end
  # TODO:
  aug_script = '/tmp/example.aug'
  aug_path = "Server/Service/Engine/Host[#attribute/name=\"localhost\"]/#attribute/name"
  program=<<-EOF
    set /augeas/load/xml/lens "Xml.lns"
    set /augeas/load/xml/incl "#{tomcat_users_xml_file}"
    load
    insert 'Context' after '/files#{tomcat_users_xml_file}/Server/Service/Engine/Host[#attribute/name="localhost"]/Valve'
    save
    set '/files#{tomcat_users_xml_file}/Server/Service/Engine/Host[#attribute/name="localhost"]/Context/#attribute/path' '/static'
    set '/files#{tomcat_users_xml_file}/Server/Service/Engine/Host[#attribute/name="localhost"]/Context/#attribute/docBase' '/var/static'
    save
  EOF
    # curl -u user1:password1 http://127.0.0.1:8080/manager/text/list
    # OK - Listed applications for virtual host [localhost]
    # /:running:0:ROOT
    # /examples:running:0:examples
    # /host-manager:running:0:host-manager
    # /manager:running:6:manager
    # /static:running:0:/var/static
    # /docs:running:0:docs
  describe command(<<-EOF
    echo '#{program}' > #{aug_script}
    # TODO:
    # augtool -f #{aug_script}
  EOF
  ) do
    let(:path) { "/bin:/usr/bin:/sbin:#{puppet_home}"}
    # its(:stdout) { should match '.*#attribute/name = "localhost"' }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end

  describe command(<<-EOF
    #{catalina_home}/bin/shutdown.sh
    #{catalina_home}/bin/startup.sh
    sleep #{tomcat_boot_delay}
    curl -u #{username}:#{password} http://127.0.0.1:8080/manager/text/list
  EOF
  ) do
    its(:stdout) { should contain 'OK - Listed applications for virtual host'}
    its(:stdout) { should contain '/:running:0:ROOT'}
    # TODO:
    # its(:stdout) { should match Regexp.new("/[^ ]+:running:\d+:[^ ]+")}
    its(:exit_status) { should eq 0 }
  end
end

