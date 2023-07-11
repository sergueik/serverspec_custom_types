require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Augeas Match' do

  # default yum install
  catalina_home = '/opt/tomcat'
  aug_script = "/tmp/example-#{Process.pid}.au"
  server_config_file = "#{catalina_home}/conf/server.xml"

  class_name = 'org.apache.catalina.core.AprLifecycleListener'
  aug_path = "Server/Listener[#attribute/className=\"#{class_name}\"]/#attribute/SSLEngine"
  aug_path_response = '/Server/Listener[2]/#attribute/SSLEngine'
  # inspecting
  # <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  # the augtool match command would print
  # matching nodes in the abbreviated augeas Path notation
  # that resembles DOM XPath
  # https://github.com/hercules-team/augeas/wiki/Path-expressions#Path_Expressions_by_Example
  program=<<-EOF
    # NOTE: no magic meaning of 'o' in the /augeas/load path
    set /augeas/load/o/lens 'Xml.lns'
    set /augeas/load/o/incl '#{server_config_file}'
    # NOTE: leading slash optional ?
    load
    ls /files/opt/tomcat/conf/server.xml/Server/Service[#attribute/name = 'Catalina' ]/
    match /files#{server_config_file}/#{aug_path} 'on'
  EOF

  describe command(<<-EOF
    echo '#{program}' > #{aug_script}
    augtool -A -f #{aug_script}
  EOF
  ) do
    let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
    its(:stdout) { should match Regexp.escape( "/files#{server_config_file}" + aug_path_response ) }
    its(:stderr) { should be_empty }
    its(:exit_status) {should eq 0 }
  end

end
