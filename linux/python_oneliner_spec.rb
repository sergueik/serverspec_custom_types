require 'spec_helper'
require 'fileutils'

# origin: https://stackoverflow.com/questions/5389507/iterating-over-every-two-elements-in-a-list
# see also https://www.geeksforgeeks.org/python-pair-iteration-in-list/
# text = 'a1,b1,a2,b2,a3,b3,a4,b4,a5,b5'
# data = text.split(',')
# for k,v in zip(data[0::2], data[1::2]):
#   print( '{} {}'.format(k,v))
context 'Python' do
  describe file ('/usr/bin/python3') do
    it { should be_file }
    it { should be_executable }
  end
  describe command( <<-EOF
    python3 -c "exec(\\\"\\\"\\\"\\\\ndata = 'a1,b1,a2,b2,a3,b3,a4,b4,a5,b5'.split(',')\\\\nfor k,v in zip(data[0::2], data[1::2]):\\\\n  print( '{}={}'.format(k,v))\\\\n\\\"\\\"\\\")"
  EOF
  ) do 
      {
        'a1' => 'b1',
        'a2' => 'b2',
        'a3' => 'b3',
      }.each do |k,v|
        its(:stdout) { should contain "#{k}=#{v}" }
      end  
  end
  xml_path = '/tmp'
  xml_file = 'server.xml'
    # NOTE: indent sensitive
  xml_data = <<-EOF
    <?xml version="1.0" encoding="utf-8"?>
    <Server port="8005" shutdown="SHUTDOWN">
      <Listener className="org.apache.catalina.core.JasperListener"/>
      <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on"/>
      <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener"/>
      <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener"/>
      <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener"/>
      <GlobalNamingResources>
        <Resource name="UserDatabase" auth="Container" type="org.apache.catalina.UserDatabase" description="User database that can be updated and saved" factory="org.apache.catalina.users.MemoryUserDatabaseFactory" pathname="conf/tomcat-users.xml"/>
      </GlobalNamingResources>
      <Service name="Catalina">
        <Connector port="8080" protocol="HTTP/1.1" connectionTimeout="20000" redirectPort="8443"/>
        <Connector port="8009" protocol="AJP/1.3" redirectPort="8443"/>
        <Engine name="Catalina" defaultHost="localhost">
          <Realm className="org.apache.catalina.realm.LockOutRealm">
            <Realm className="org.apache.catalina.realm.UserDatabaseRealm" resourceName="UserDatabase"/>
          </Realm>
          <Host name="localhost" appBase="webapps" unpackWARs="true" autoDeploy="true">
            <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs" prefix="localhost_access_log." suffix=".txt" pattern="%h %l %u %t %r %s %b"/>
          </Host>
        </Engine>
      </Service>
    </Server>
  EOF
  before(:each) do
    Dir.chdir xml_path
    $stderr.puts "Writing #{xml_path}/#{xml_file}"
    file = File.open(xml_file, 'w')
    xml_data.strip!
    file.puts(xml_data)
    file.close
  end
  describe command( <<-EOF
    python3 -c 'import sys; from xml.dom import minidom; x=minidom.parse(sys.argv[1]); n = x.getElementsByTagName("Server")[0];n.setAttribute("port","-1");n.setAttribute("shutdown","MWSSTOP");x.writexml(open(sys.argv[2], "w+"));' #{xml_path}/#{xml_file} /tmp/#{xml_file}.NEW
   xmllint --xpath '//Server[@shutdown="MWSSTOP"]/@port' /tmp/#{xml_file}.NEW
  EOF
  ) do 
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain('port="-1"') }
    its(:stderr) { should be_empty }

  end
end
