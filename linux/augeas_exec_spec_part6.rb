require 'spec_helper'
require 'erb'

# https://www.stuartellis.name/articles/erb/
# https://www.systutorials.com/docs/linux/man/1-augtool/
# http://blog.chalda.cz/2017/09/30/Augeas-and-XML.html
context 'Augeas defvar and template' do

  # default yum install
  catalina_home = '/usr/share/tomcat'
  catalina_conf = "#{catalina_home}/conf"
  catalina_conf = '/tmp'
  xml_file = "#{catalina_conf}/web.xml"
  xml_data = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<!-- fragment of tomcat 8.5 web.xml -->
<web-app>
  <servlet>
    <servlet-name>ssi</servlet-name>
    <servlet-class>
      org.apache.catalina.ssi.SSIServlet
    </servlet-class>
    <init-param>
      <param-name>buffered</param-name>
      <param-value>1</param-value>
    </init-param>
    <init-param>
      <param-name>debug</param-name>
      <param-value>0</param-value>
    </init-param>
    <init-param>
      <param-name>expires</param-name>
      <param-value>666</param-value>
    </init-param>
    <init-param>
      <param-name>isVirtualWebappRelative</param-name>
      <param-value>false</param-value>
    </init-param>
    <load-on-startup>4</load-on-startup>
  </servlet>
</web-app>

EOF
  aug_script = '/tmp/example.aug'
  aug_common_path = '/web-app/servlet/init-param'


  context 'Augeas defvar' do
    program = <<-EOF
      set /augeas/load/xml/lens 'Xml.lns'
      set /augeas/load/xml/incl '#{xml_file}'
      load
      defvar node /files#{xml_file}/#{aug_common_path}
      dump-xml $node
      set name 'buffered'
      get name
      defvar value $node/param-name[#text = /files/name]/../param-value/#text
      print $value
      get $value
      # noisy
      # print '/augeas//error'
      print '/augeas/files#{xml_file}/error'
      quit
    EOF
    describe command(<<-EOF
      echo '#{program}' > #{aug_script}
      augtool -f #{aug_script}
    EOF
    ) do
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
      its(:stderr) { should be_empty }
      its(:stdout) { should contain 'name = buffered' }
      its(:stdout) { should contain '\$value = 1' }
      its(:exit_status) {should eq 0 }
    end
  end
  context 'ERB Template' do
    context 'Success' do
      program_template =<<-EOF
        set /augeas/load/xml/lens "Xml.lns"
        set /augeas/load/xml/incl "#{xml_file}"
        load
        defvar node /files#{xml_file}/#{aug_common_path}
        # dump-xml $node
        <% for param_name in param_names %>
          set param_name '<%= param_name %>'
          defvar param_value $node/param-name[#text = /files/param_name]/../param-value/#text
          get param_name
          get $param_value
        <% end %>
        print '/augeas/files#{xml_file}/error'
        quit
      EOF
      param_names = [
        'buffered',
        'debug',
        'expires',
        'isVirtualWebappRelative',
      ]
      renderer = ERB.new(program_template)
      program = renderer.result(binding)
      describe command(<<-EOF
        echo '#{program}' > #{aug_script}
        augtool -f #{aug_script}
      EOF
      ) do
        let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
        param_names.each do |param_name|
          its(:stdout) { should contain "param_name = #{param_name}" }
        end
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
      end
    end
    context 'Not Found' do
      program_template =<<-EOF
        set /augeas/load/xml/lens "Xml.lns"
        set /augeas/load/xml/incl "#{xml_file}"
        load
        defvar node /files#{xml_file}/#{aug_common_path}
        # dump-xml $node
        <% for param_name in param_names %>
          set param_name '<%= param_name %>'
          defvar param_value $node/param-name[#text = /files/param_name]/../param-value/#text
          get param_name
          get $param_value
        <% end %>
        print '/augeas/files#{xml_file}/error'
        quit
      EOF
      param_names = [
        'missing',
      ]
      renderer = ERB.new(program_template)
      program = renderer.result(binding)
      describe command(<<-EOF
        echo '#{program}' > #{aug_script}
        augtool -f #{aug_script}
      EOF
      ) do
        let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
        param_names.each do |param_name|
          its(:stdout) { should contain '\$param_value \(o\)'  }
        end
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
      end
    end
    context 'Hashes' do
      program_template =<<-EOF
        set /augeas/load/xml/lens "Xml.lns"
        set /augeas/load/xml/incl "#{xml_file}"
        load
        defvar node /files#{xml_file}/#{aug_common_path}
        # dump-xml $node
        <% for param_name in params.keys %>
          set param_name '<%= param_name %>'
          defvar param_value $node/param-name[#text = /files/param_name]/../param-value/#text
          get param_name
          get $param_value
        <% end %>
        print '/augeas/files#{xml_file}/error'
        quit
      EOF
      params = {
        'buffered' => 1,
      }
      renderer = ERB.new(program_template)
      program = renderer.result(binding)
      describe command(<<-EOF
        echo '#{program}' > #{aug_script}
        augtool -f #{aug_script}
      EOF
      ) do
        let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
        params.each do |name,value|
          its(:stdout) { should match /param_name = #{name}/ }
          its(:stdout) { should match /\$param_value = #{value}/  }
        end
        its(:stderr) { should be_empty }
        its(:exit_status) {should eq 0 }
      end
    end
  end
end