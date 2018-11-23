require 'spec_helper'

context 'Augeas Print' do

  # default yum install
  catalina_home = '/usr/share/tomcat'
  aug_script = '/tmp/example.aug'
  aug_script_result = '/tmp/example.result.log'
  xml_file = "#{catalina_home}/conf/server.xml"

  # Tomcat 8
  class_name = 'org.apache.catalina.security.SecurityListener'
  aug_node_index = '2'

  # Tomcat 7
  class_name = 'org.apache.catalina.core.JreMemoryLeakPreventionListener'
  aug_node_index = '3'

  aug_path = "//Listener[#attribute/className=\"#{class_name}\"]"

  program=<<-EOF
    set /augeas/load/xml/lens "Xml.lns"
    set /augeas/load/xml/incl "#{xml_file}"
    load
    print #{aug_path}
  EOF
  describe command(<<-EOF
    echo '#{program}' > #{aug_script}
    augtool -A -f #{aug_script} | tee #{aug_script_result}
  EOF
  ) do
   let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
   its(:stderr) { should be_empty }
   its(:exit_status) {should eq 0 }
   # the match is fragile to fail due to presence of libReadLine special characters in the Augeas DSL
   [
     "/files#{xml_file}/Server/Listener\\[#{aug_node_index}\\]",
     "/files#{xml_file}/Server/Listener\\[#{aug_node_index}\\]/#attribute",
     "/files#{xml_file}/Server/Listener\\[#{aug_node_index}\\]/#attribute/className = \"#{class_name}\"",
   ].each do |line|
     its(:stdout) { should match /#{line}/ }
   end
  end
  # https://github.com/hercules-team/augeas/wiki/Path-expressions#Path_Expressions_by_Example
  describe file(aug_script_result) do
   [
     "/files#{xml_file}/Server/Listener\\[#{aug_node_index}\\]",
     "/files#{xml_file}/Server/Listener\\[#{aug_node_index}\\]/#attribute",
     "/files#{xml_file}/Server/Listener\\[#{aug_node_index}\\]/#attribute/className = \"#{class_name}\"",
   ].each do |line|
     its(:content) { is_expected.to match Regexp.new(line) }
   end
  end
end