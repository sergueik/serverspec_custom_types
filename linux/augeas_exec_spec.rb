require 'spec_helper'

context 'Augeas' do

  catalina_home = '/apps/tomcat/current'
  aug_script = '/tmp/example.aug'
  xml_file = "#{catalina_home}/conf/server.xml"

  # uses puppet augtool to verify expectations of the systemd service
  # dependenciees:
  #   $ augtool
  #   augtool> ls /files/lib/systemd/system/systemd-networkd.socket/Unit/Before
  #   value = sockets.target
  #   augtool> quit
  context 'Systemd Services' do
    service_name = 'systemd-networkd.socket'
    service_dependency = 'sockets.target'
    program=<<-EOF
      print /files/lib/systemd/system/#{service_name}/Unit/Before
    EOF

    describe command(<<-EOF
      echo '#{program}' > #{aug_script}
      augtool -f #{aug_script}
    EOF
    ) do
      # NOTE: augtool may get installed strictly into Puppet applicarion directory
      # or under /usr/bin
      # when installed standalone by apt-get install augeas-tools
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/bin'}
      its(:stdout) { should match Regexp.new("/files/lib/systemd/system/#{service_name}/Unit/Before/value = \"#{service_dependency}\"") }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'Use Puppet Augeas Provider to no-op modify the Tomcat server.xml' do
    tcp_port = '8443'
    describe command(<<-EOF
      puppet apply -e 'augeas {"tomcat sever aug": show_diff=> true, lens => "Xml.lns", incl => "#{catalina_home}/conf/server.xml", changes => [ "set Server/Service/Connector[#attribute/port=\\"#{tcp_port}\\"]/#attribute/port \\"#{tcp_port}\\""],}'
    EOF
    ) do
      # NOTE: using Puppet apply is a bad idea, since it leads to creation of new XML nodes in the target file when no matching nodes found
      # e.g. <Connector></Connector>
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/bin'}
      its(:stdout) { should match /Notice: Applied catalog/ }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'Use Puppet Augeas Provider to no-op modify the Apache httpd.conf' do
    apache_home = '/apps/apache/current'
    node_server_name = 'node-server-name'
    describe command(<<-EOF
      puppet apply -e 'augeas {"apache aug": lens => "Httpd.lns", incl => "#{apache_home}/etc/httpd/conf/httpd.conf", context => "/files/#{apache_home}/etc/httpd/conf/httpd.conf", changes => "set directive[.=\\"ServerName\\"]/arg \\"#{node_server_name}.puppet.localdomain\\" ",}'
    EOF
    ) do
      # NOTE: using Puppet apply is a bad idea,      # since it leads to corrupting the configuration when no match found
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/bin'}
      its(:stdout) { should match /Notice: Applied catalog/ }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'Use Augeas Commands to inspect the Tomcat server.xml' do
    context 'Multiple nodes' do
      class_names = [
        'org.apache.catalina.startup.VersionLoggerListener',
        'org.apache.catalina.security.SecurityListener',
        'org.apache.catalina.core.AprLifecycleListener',
        'org.apache.catalina.core.JreMemoryLeakPreventionListener',
        'org.apache.catalina.mbeans.GlobalResourcesLifecycleListener',
        'org.apache.catalina.core.ThreadLocalLeakPreventionListener',
      ]
      aug_path = 'Server/Listener/#attribute/className'
      program=<<-EOF
        set /augeas/load/xml/lens "Xml.lns"
        set /augeas/load/xml/incl "#{xml_file}"
        load
        print /files#{xml_file}/#{aug_path}
      EOF
      describe command(<<-EOF
        echo '#{program}' > #{aug_script}
        augtool -f #{aug_script}
      EOF
      ) do
        let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
        class_names.each do |class_name|
          its(:stdout) { should match class_name }
        end
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
      end
    end
    context 'Single node' do
      class_name = 'org.apache.catalina.startup.VersionLoggerListener'
      aug_path = "Server/Listener[1][#attribute/className=\"#{class_name}\"]/#attribute/className"
      program=<<-EOF
        set /augeas/load/xml/lens "Xml.lns"
        set /augeas/load/xml/incl "#{xml_file}"
        load
        print /files#{xml_file}/#{aug_path}
     EOF
     describe command(<<-EOF
       echo '#{program}' > #{aug_script}
       augtool -f #{aug_script}
     EOF
     ) do
       let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
       its(:stdout) { should match class_name }
       its(:stderr) { should be_empty }
       its(:exit_status) {should eq 0 }
     end
   end
 end
 context 'Matched node' do
   class_name = 'org.apache.catalina.startup.VersionLoggerListener'
   aug_path = "Server/Listener[#attribute/className=\"#{class_name}\"]/#attribute/className"
   # the augtool match command returns a set of matching nodes via their abbreviated aug path e.g.
   aug_path_response = 'Server/Listener[1]/#attribute/className'
   program=<<-EOF
     set /augeas/load/xml/lens "Xml.lns"
     set /augeas/load/xml/incl "#{xml_file}"
     load
     match /files#{xml_file}/#{aug_path} #{class_name}
   EOF
   describe command(<<-EOF
     echo '#{program}' > #{aug_script}
     augtool -f #{aug_script}
   EOF
   ) do
     let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
     its(:stdout) { should match Regexp.escape(aug_path_response) }
     its(:stderr) { should be_empty }
     its(:exit_status) {should eq 0 }
   end
   class_name = 'org.apache.catalina.security.SecurityListener'
   aug_path = "//Listener[#attribute/className=\"#{class_name}\"]"
   # the augtool print command returns a matching node with all of its contents expressed in abbreviated aug path e.g.
   aug_node_index = '2'
   program=<<-EOF
     set /augeas/load/xml/lens "Xml.lns"
     set /augeas/load/xml/incl "#{xml_file}"
     load
     print #{aug_path}
   EOF
   describe command(<<-EOF
     echo '#{program}' > #{aug_script}
     augtool -f #{aug_script}
   EOF
   ) do
     let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
     its(:stderr) { should be_empty }
     its(:exit_status) {should eq 0 }
     [
       "/files/apps/tomcat/current/conf/server.xml/Server/Listener[#{aug_node_index}]",
       "/files/apps/tomcat/current/conf/server.xml/Server/Listener[#{aug_node_index}]/#attribute",
       "/files/apps/tomcat/current/conf/server.xml/Server/Listener[#{aug_node_index}]/#attribute/className = \"#{class_name}\"",
     ].each do |aug_response|
       its(:stdout) { should match Regexp.escape(aug_response) }
     end
   end
 end
 context 'Text of the node' do
   # generated text attriute we do now know in advance the exact value
   aug_script = '/tmp/test.aug'
   xml_file = '/opt/app/wso2/apim/store/repository/conf/registry.xml'
   aug_path = "wso2registry/indexingConfiguration/lastAccessTimeLocation/#text"
   aug_path_response = '/_system/local/repository/components/org.wso2.carbon.registry/indexing/lastaccesstime_\d{10}'
   program=<<-EOF
     set /augeas/load/xml/lens "Xml.lns"
     set /augeas/load/xml/incl "#{xml_file}"
     load
     match /files#{xml_file}/#{aug_path}
   EOF
   describe command(<<-EOF
     echo '#{program}' > #{aug_script}
     augtool -f #{aug_script}
   EOF
   ) do
     let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
     its(:stdout) { should match /#{aug_path_response}/i }
     its(:stderr) { should be_empty }
     its(:exit_status) {should eq 0 }
    end
  end
end
