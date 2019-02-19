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
  <!--Match on Attributes, Elements, text nodes, and Processing Instructions-->
  <xsl:template match="@*| * | text() | processing-instruction()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  <!--Empty template prevents comments from being copied into the output -->
  <xsl:template match="comment()"/>
</xsl:stylesheet>
EOF
  # real Appdynamics "controller-info.xml"
  # origin: https://github.com/xebialabs-community/xld-appDynamics-plugin/blob/master/src/main/resources/appdynamics/controller-info.xml

  # Fragment of real Appdynamics "controller-info.xml"
  # origin: https://github.com/xebialabs-community/xld-appDynamics-plugin/blob/master/src/main/resources/appdynamics/controller-info.xml

    controller_info_datafile = '/tmp/controller-info.xml'
    controller_info_content = <<-EOF
<?xml version="1.0"?>
<controller-info>
  <controller-host>${container.controllerHost}</controller-host>
  <!--  This is the http(s) port of the AppDynamics Controller , If 'controller-ssl-enabled' below is set to true, you must
    specify the HTTPS port of the Controller, otherwise specify the HTTP port. Controller gets installed at port 8090 by default.
    If you set 'controller-ssl-enabled' to true, the Controller installs at port 8181.
    If you are using a saas controller, the ssl port is 443
    This is the same port that you use to access the AppDynamics browser based User interface.
    This can be overridden with an environment variable 'APPDYNAMICS_CONTROLLER_PORT' or
    the system property '-Dappdynamics.controller.port'  -->
  <account-access-key>${container.accountAccessKey}</account-access-key>
  <!--  Change to 'true' only under special circumstances where this agent has been moved to a new application and/or tier
    from the UI but you want to override that move by specifying a new application name and/or tier name in the agent configuration.  -->
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
#{identity_transform_content}
DATA1
        # no space at beginning of the document is critical for xml
        cat<<DATA2|tee #{controller_info_datafile}
#{controller_info_content}
DATA2
      EOF
    )
    end
    [
      # cannot make xmllint apply style sheet, it appears
      # for the spec simply getting a fearment is a good enough
      "xmllint --xpath '//*' '#{controller_info_datafile}'",
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


