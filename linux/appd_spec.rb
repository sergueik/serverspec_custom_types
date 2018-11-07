require 'spec_helper'

# https://docs.appdynamics.com/display/PRO42/Install+the+Java+Agent
context 'AppDynamics signature spec' do
  service = 'wso2-gateway'
  appdymanics_jar = '/opt/appdynamics/appdservergent/javaagent.jar'
  describe command("systemctl --no-page -o cat show '#{service}' | grep 'Environment'| sed 's|\\\\x20|\\n|g'") do
    its(:stdout) { should contain '-javaagent:#{appdymanics_jar}" }
  end
  # alternatively scan the jps -vv output
end