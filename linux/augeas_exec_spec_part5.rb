require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Augeas Multiple nodes' do

  # default yum install
  catalina_home = '/usr/share/tomcat'
  aug_script = '/tmp/example.aug'
  xml_file = "#{catalina_home}/conf/server.xml"
  class_names = [
    'org.apache.catalina.startup.VersionLoggerListener',
   # specific to Tomcat 8
   # 'org.apache.catalina.security.SecurityListener',
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