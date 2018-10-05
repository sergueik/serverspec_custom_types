if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end

require 'rexml/document'
include REXML

context 'Server XML' do
  catalina_home = '/apps/tomcat/current'
  server_xml = "#{catalina_home}/conf/server.xml"

  describe file("#{catalina_home}/conf/server.xml") do
    begin
      content = Specinfra.backend.run_command("cat #{server_xml}").stdout
    rescue => e
      $stderr.puts e.to_s
    end
    # Example emulates an tomcat server.xml configuration file '/opt/tomcat/current/conf/server.xml'
    # NOTE: no leading whitespace allowed by XML spec
    content = <<-EOF
<?xml version='1.0' encoding='utf-8'?>
  <Server port="8005" shutdown="SHUTDOWN">
    <Listener className="org.apache.catalina.core.JasperListener" />
    <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
    <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
    <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
    <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
    <GlobalNamingResources>
      <Resource name="UserDatabase" auth="Container"
                type="org.apache.catalina.UserDatabase"
                description="User database that can be updated and saved"
                factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
                pathname="conf/tomcat-users.xml" />
    </GlobalNamingResources>
    <Service name="Catalina">
      <Connector port="8080" protocol="HTTP/1.1"
                 connectionTimeout="20000"
                 redirectPort="8443" />
      <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />
      <Engine name="Catalina" defaultHost="localhost">
        <Realm className="org.apache.catalina.realm.LockOutRealm">
          <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
                 resourceName="UserDatabase"/>
        </Realm>
        <Host name="localhost"  appBase="webapps"
             unpackWARs="true" autoDeploy="true">
          <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
                 prefix="localhost_access_log." suffix=".txt"
                 pattern="%h %l %u %t %r %s %b" />
        </Host>
      </Engine>
    </Service>
  </Server>
    EOF
    begin
      doc = Document.new(content)
    rescue ParseException =>  e
      # Will indicate the document is not well-formed
      $stderr.puts e.to_s
    end
    describe 'redirectPort 8080' do
      redirect_port = '8443'
      port = '8080'
      xpath = "/Server/Service/Connector[@port = \"#{port}\"]/@redirectPort"
      result = REXML::XPath.first(doc, xpath).value
      $stderr.puts result
      it { result.should match redirect_port }
    end
    describe 'Closures' do
      class_name = 'org.apache.catalina.core.JasperListener'
      result = false
      doc.elements.each('Server/Listener') do |node|
        # $stderr.puts node.attributes['className']
        if node.attributes['className'] =~ /#{class_name}/
          $stderr.puts node
          result =  true
        end
      end
      $stderr.puts result
      it { result.should be_truthy }
    end
    # TODO - explore if syntax below ... is possible with REXML
    # result = doc.root.elements['Server'].elements['Service'].elements['Connector'].attributes['port']
  end
end
