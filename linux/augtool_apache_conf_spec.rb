require 'spec_helper'

context 'Augeas' do

  # defaultlocation of the apache config installed by yum
  apache_home = '/etc/httpd'
  config_file = "#{apache_home}/conf.d/mime_magic.conf"

  # uses puppet augtool to verify expectation of the MIME file to be disabled
  describe command(<<-EOF
    augtool -e 'ls /files/#{config_file}/'
  EOF
  ) do
      # NOTE: augtool usually gets installed strictly into Puppet applicarion directory, with no alternatives
      # when installed standalone by apt-get install augeas-tools
      # it is in /usr/bin
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/bin'}
      its(:stdout) { should match '#comment = MIMEMagicFile "/etc/httpd/conf/magic"' } # disabled
      its(:stdout) { should_not match 'directive/ = MIMEMagicFile' } # enabled
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
  end
end

