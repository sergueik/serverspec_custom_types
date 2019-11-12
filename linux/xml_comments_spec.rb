require 'spec_helper'
require 'rexml/document'
begin
  # http://www.w3big.com/ruby/ruby-xml-xslt-xpath.html
  require 'xslt'
rescue LoadError => e
  # cannot load such file -- xslt
end
include REXML

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

context 'Strip xml comments spec' do
  identity_transform_datafile = '/tmp/identity.xml'
  identity_transform_content = <<-EOF
    <?xml version="1.0"?>
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
      <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
      <!-- Matches on
         Attributes,
	 Elements,
	 text nodes, and
	 Processing Instructions -->
      <xsl:template match="@*| * | text() | processing-instruction()">
        <xsl:copy>
          <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
      </xsl:template>
      <!-- Empty template prevents comments from being copied into the output -->
      <xsl:template match="comment()"/>
    </xsl:stylesheet>
  EOF
  # A fragment of real Appdynamics "controller-info.xml" is used
  # origin: https://github.com/xebialabs-community/xld-appDynamics-plugin/blob/master/src/main/resources/appdynamics/controller-info.xml
  # https://docs.appdynamics.com/display/PRO14S/Install+the+App+Agent+for+Java#InstalltheAppAgentforJava-5.ConfigurehowtheagentidentifiestheAppDynamicsbusinessapplication,tier,andnode.
  controller_info_datafile = '/tmp/controller-info.xml'
  controller_info_content = <<-EOF
    <?xml version="1.0"?>
    <controller-info>
      <controller-host>${container.controllerHost}</controller-host>
      <!--  This is the http(s) port of the AppDynamics Controller , If 'controller-ssl-enabled' below is set to true, you must specify the HTTPS port of the Controller, otherwise specify the HTTP port. Controller gets installed at port 8090 by default. -->
      <account-access-key>${container.accountAccessKey}</account-access-key>
      <!--  Change to 'true' only under special circumstances where this agent has been moved to a new application and/or tier -->
      <force-agent-registration>false</force-agent-registration>
      <auto-naming>true</auto-naming>
    </controller-info>
  EOF
  controller_info_content.gsub!(/\$/, '\\$')
  before(:each) do
    $stderr.puts "Writing #{identity_transform_datafile}"
    Specinfra::Runner::run_command( <<-EOF
      # no space at beginning of the document is critical for xml
      cat<<DATA1|tee #{identity_transform_datafile}
#{identity_transform_content.strip}
DATA1
      cat<<DATA2|sed 's|^\\s\\s*||' |tee #{controller_info_datafile}
          #{controller_info_content.strip}
DATA2
      EOF
    )
    end
    [
      # both --format or -format option would work
      "xsltproc '#{identity_transform_datafile}' '#{controller_info_datafile}' | xmllint --format -",
      # cannot have xmllint apply style sheet, it appears
      # for the spec simply getting a fragment is a good enough
      # comments will remain
      # "xmllint --xpath '//*' '#{controller_info_datafile}'",
      "xmlstarlet c14n --without-comments '#{controller_info_datafile}'",
    ].each do |commandline|
      describe command(<<-EOF
        #{commandline}
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should_not contain 'want to override that move by specify' }
    end
  end
end


