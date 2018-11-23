require 'spec_helper'

context 'Augeas Match' do

  # default yum install
  catalina_home = '/usr/share/tomcat'
  aug_script = '/tmp/example.aug'
  xml_file = "#{catalina_home}/conf/server.xml"

  class_name = 'org.apache.catalina.startup.VersionLoggerListener'
  aug_path = "Server/Listener[#attribute/className=\"#{class_name}\"]/#attribute/className"
  # the augtool match command would print 
  # matching nodes in the abbreviated augeas Path notation
  # https://github.com/hercules-team/augeas/wiki/Path-expressions#Path_Expressions_by_Example
  aug_path_response = 'Server/Listener[1]/#attribute/className'
  program=<<-EOF
    set /augeas/load/xml/lens "Xml.lns"
    set /augeas/load/xml/incl "#{xml_file}"
    load
    match /files#{xml_file}/#{aug_path} #{class_name}
  EOF

  describe command(<<-EOF
    echo '#{program}' > #{aug_script}
    augtool -A -f #{aug_script}
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:stdout) { should match Regexp.escape( "/files#{xml_file}" + aug_path_response ) }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end

end