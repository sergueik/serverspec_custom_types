require 'spec_helper'

context 'Augeas Single node' do

  # default yum install
  catalina_home = '/usr/share/tomcat'
  aug_script = '/tmp/example.aug'
  xml_file = "#{catalina_home}/conf/server.xml"

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