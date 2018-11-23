require 'spec_helper'

context 'Augeas' do

  # default yum instll
  catalina_home = '/usr/share/tomcat'
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
  context 'Use Puppet Augeas Provider against Tomcat server.xml' do
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
  # NOTE: hanging
  context 'Use Puppet Augeas Provider against Apache httpd.conf' do
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
end
