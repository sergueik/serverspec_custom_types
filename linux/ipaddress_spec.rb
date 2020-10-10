require 'spec_helper'

context 'single-homed node ip address' do

  # NOTE: trailing space after "inet" in processing the ifconfig command
  describe command(<<-EOF
    ifconfig $(ls -1 /sys/class/net | grep -v lo | grep -v docker ) | grep 'inet ' | awk '{print $2}'
  EOF

  ) do
    its(:stdout) { should match /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/}
  end
  describe command(<<-EOF
    IP=$(ifconfig $(ls -1 /sys/class/net | grep -vE '(lo|docker)' ) | grep 'inet ' | awk '{print $2}')
    hostname -I | grep $IP
  EOF
  ) do
    its(:exit_status) { should be 0 }
  end
end
