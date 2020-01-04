# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'spec_helper'

# proper way of using checksum file
# origin: https://github.com/chorrell/docker-image-testing-example/blob/master/12.10/Dockerfile
# converted from a Dockerfile RUN command which was compressed to save the number on intermediate images

context 'checksum validation' do
  repo_base_url = 'https://nodejs.org/dist'
  package_version = '12.9.1'
  package_filename = "node-v#{package_version}-linux-x64.tar.xz"
  package_checksum_file = 'SHASUMS256.txt.asc'

  describe command(<<-EOF
    1>/dev/null 2>/dev/null pushd /tmp
    REPO_BASE_URL='#{repo_base_url}'
    PACKAGE_VERSION='#{package_version}'
    PACKAGE_FILENAME='#{package_filename}'
    PACKAGE_CHECKSUM_FILE='#{package_checksum_file}'
    curl -fsSLO --compressed "${REPO_BASE_URL}/v${PACKAGE_VERSION}/${PACKAGE_FILENAME}"
    1>&2 echo Downloading package "${REPO_BASE_URL}/v${PACKAGE_VERSION}/${PACKAGE_FILENAME}"
    curl -fsSLO --compressed "${REPO_BASE_URL}/v${PACKAGE_VERSION}/${PACKAGE_CHECKSUM_FILE}"
    1>&2 echo Downloading checksum "${REPO_BASE_URL}/v${PACKAGE_VERSION}/${PACKAGE_CHECKSUM_FILE}"
    gpg --batch --decrypt --output checksum.txt $PACKAGE_CHECKSUM_FILE
    rm -f checksum.txt
    grep " $PACKAGE_FILENAME\$" checksum.txt | sha256sum -c -
    1>/dev/null 2>/dev/null popd
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain "#{package_filename}: OK" }
    its(:stderr) { should be_empty }
  end
end