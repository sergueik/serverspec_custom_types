require 'spec_helper'
require 'rexml/document'
include REXML

# Verifies that Puppet adds the following configuration fragment to jetty.xml:
#  <New id="RewriteHandler" class="org.eclipse.jetty.rewrite.handler.RewriteHandler">
#    <Set name="rules">
#      <Array type="org.eclipse.jetty.rewrite.handler.Rule">
#        <Item>
#          <New id="header1" class="org.eclipse.jetty.rewrite.handler.HeaderPatternRule">
#            <Set name="pattern">*</Set>
#            <Set name="name">Content-Security-Policy</Set>
#            <Set name="value">frame-ancertors 'self' *.domain.net</Set>
#          </New>
#        </Item>
#      </Array>
#    </Set>
#  </New>
#
#  <Set name="handler">
#    <New id="Handlers" class="org.eclipse.jetty.server.handler.HandlerCollection">
#      <Set name="handlers">
#        <Array type="org.eclipse.jetty.server.Handler">
#          <Item>
#            <Ref id="RewriteHandler"/>
#          </Item>
#        </Array>
#      </Set>
#    </New>
#  </Set>
context 'xmllint' do
  # https://stackoverflow.com/questions/3009631/setting-http-headers-with-jetty
  jetty_home = '/opt/openidm'
  node_index = 3
  jetty_home = '/tmp'
  node_index = 1
  jetty_xml = "#{jetty_home}/conf/jetty.xml"
  # NOTE: the web.xml is using namespaces
  context 'Single rule' do
    describe command(<<-EOF
      xmllint --xpath '//New[@id="RewriteHandler"]/Set[@name="rules"]/Array/Item[#{node_index}]/New[contains(@id,"header")]/Set[@name = "pattern"]/text()' '#{jetty_xml}'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match( /\*/ )}
      its(:stderr) { should be_empty }
    end
  end
  context 'Multiple rule' do
    describe command(<<-EOF
      xmllint --xpath '//New[@id="RewriteHandler"]/Set[@name="rules"]/Array/Item/New[contains(@id,"header")]/Set[@name = "pattern"]' '#{jetty_xml}' | sed -n 's|><|>\\n<|p'
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      [
        '*',
        '*.htm'
      ].each do |node_text|
        its(:stdout) { should match( Regexp.new( '>' +Regexp.escape(node_text) + '<', Regexp::IGNORECASE) )}
      end
      its(:stderr) { should be_empty }
    end
  end
end