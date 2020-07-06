require 'spec_helper'

context 'Disk filesystem spec' do
  # https://fibrevillage.com/storage/53-lsblk-command-examples
  # https://gist.github.com/olih/f7437fb6962fb3ee9fe95bda8d2c8fa4
  # https://thoughtbot.com/blog/jq-is-sed-for-json
  describe command("lsblk -J -f -e 0,11 | jq --slurp '.[]|.blockdevices[]| .name'"), :if => ['debian', 'ubuntu'].include?(os[:family]) do
    its(:stdout) { should contain 'sda' }
    # TODO: better querying
  end
  # https://gist.github.com/olih/f7437fb6962fb3ee9fe95bda8d2c8fa4
  describe command(<<-EOF
    lsblk -J -f -e 0,11 | jq --slurp '.[]|.blockdevices[]|.children[]|select(.fstype == "ext4")'
  EOF
  ), :if => ['centos', 'ubuntu'].include?(os[:family]) do
    its(:stdout) { should contain '"fstype": "ext4",' }
    its(:stdout) { should contain '"mountpoint": "/"' }
  end
end












