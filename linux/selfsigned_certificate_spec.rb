require 'spec_helper'
# Copyright (c) Serguei Kouzmine
#
# based on: https://superuser.com/questions/1428012/cant-verify-an-openssl-certificate-against-a-self-signed-openssl-certificate
# see also: https://blog.miguelgrinberg.com/post/running-your-flask-application-over-https
# TODO: find where Flask stores its short-living self-signed certificate
context 'SSL verify Self-Signed Certificate' do

  cert_file = '/etc/ssl/apache2/server.crt'
  issuer = 'CN = example.com'

  describe file cert_file do
     it { should be_file }
  end
  describe command(<<-EOF
    openssl x509 -in #{cert_file} -noout -issuer
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    ciphers.each do |cipher|
      its(:stdout) { should match Regexp.new('issuer=' + issuer, Regexp::IGNORECASE) }
    end
    its(:stderr) { should be_empty }
  end
  describe command(<<-EOF
    openssl verify -CAfile #{cert_file} #{cert_file}
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    ciphers.each do |cipher|
      its(:stdout) { should match Regexp.new( cert_file + ': OK', Regexp::IGNORECASE) }
    end
    its(:stderr) { should be_empty }
  end
end
