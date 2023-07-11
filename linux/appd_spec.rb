require 'spec_helper'
# Copyright (c) Serguei Kouzmine

# https://docs.appdynamics.com/display/PRO42/Install+the+Java+Agent
context 'AppDynamics signature spec' do
  context 'Java agent' do
  service = 'wso2-gateway'
  appdymanics_jar = '/opt/appdynamics/appagent/javaagent.jar'
  describe command("systemctl --no-page -o cat show '#{service}' | grep 'Environment'| sed 's|\\\\x20|\\n|g'") do
    its(:stdout) { should contain "-javaagent:#{appdymanics_jar}" }
  end
  # alternatively scan the jps -v output
  end
  # https://community.appdynamics.com/t5/Knowledge-Base/How-do-I-use-the-Analytics-Agent-health-check-URL/ta-p/25783
  # TODO: examine health check response JSON
  # curl http://localhost:9091/healthcheck?pretty=true
  # https://github.com/andrewwardrobe/serverspec-extra-types/blob/master/lib/serverspec_extra_types/types/curl.rb
  context 'Machine agent' do
    %w|9090 9091|.each do |p|
      describe port(p) do
        it { should be_listening.with('tcp')
      end
    end	
  end
end
