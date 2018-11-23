require 'spec_helper'

context 'Augeas Text of the node' do

  # default yum install
  catalina_home = '/usr/share/tomcat'
  aug_script = '/tmp/example.aug'
  xml_file = "#{catalina_home}/conf/server.xml"
  xml_file = '/opt/app/wso2/apim/store/repository/conf/registry.xml'
  # generated text attribute which exact value we do now know in advance
  aug_script = '/tmp/test.aug'
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