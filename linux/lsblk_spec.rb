require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Disk filesystem spec' do
  # https://fibrevillage.com/storage/53-lsblk-command-examples
  # https://gist.github.com/olih/f7437fb6962fb3ee9fe95bda8d2c8fa4
  # https://thoughtbot.com/blog/jq-is-sed-for-json
  context 'JSON output format', :if=> ['debian', 'ubuntu'].include?(os[:family]) do
    describe command("lsblk -J -f -e 0,11 | jq --slurp '.[]|.blockdevices[]| .name'")
      its(:stdout) { should contain 'sda' }
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
  context 'Pair output format', :if => ['centos', 'redhat'].include?(os[:family]) do
    describe command(<<-EOF
      lsblk -P -f -e 0,11 | | grep 'MOUNTPOINT="/"'
    EOF
    )
      its(:stdout) { should contain 'FSTYPE="xfs"' }
    end
  end
end












