require 'spec_helper'

# https://en.wikipedia.org/wiki/Year_2038_problem
context 'linux end date in Splunk license file' do
  splunk_base_dir = '/opt/splunk/'
  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd '#{splunk_base_dir}'
    LICENSE_FILE='etc/licenses/forwarder/splunforwarder.lic'
    EXPIRATION_TIME=$(xmllint --xpath '/licence/payload//expiration_time/text()' $LICENSE_FILE)
    date -d "1970-01-01 UTC+ ${EXPIRATION_TIME} seconds"
  EOF
  ) do
    its(:stdout) { should contain 'Tue Jan 19 11:51:18 2038' }
  end
end
