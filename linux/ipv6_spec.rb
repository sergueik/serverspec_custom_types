require 'spec_helper'
# Copyright (c) Serguei Kouzmine

# This spec contains both passing and failing expectations, one for ipv6 enabled and disabled
# based on: https://linuxconfig.org/how-to-disable-ipv6-address-on-ubuntu-18-04-bionic-beaver-linux
$ipv6_disabled = true
context 'IPv6 configuration' do
  target_host = 'www.google.com'
  context 'IP v6 disabled', :if => $ipv6_disabled do
    describe command 'ip -f inet6 a' do
      its(:stdout) { should be_empty }
    end
    describe command "ping -c 1 #{target_host} 2>/dev/null| tr ')( ' '\\n' | grep -iE '[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+'| head -1" do
      its(:stdout) { should match /\d+.\d+.\d+.\d+/ }
    end
  end
  # instantly disable the IP version 6 network protocol system on on Ubuntu 18.04
  context 'instantly disable the IP v6', :if => ENV.fetch('USER').eql?('root') do
    describe command 'sysctl -w net.ipv6.conf.all.disable_ipv6=1' do
      its(:stdout) { should contain 'net.ipv6.conf.all.disable_ipv6 = 1' }
    end
    describe command 'sysctl -w net.ipv6.conf.default.disable_ipv6=1' do
      its(:stdout) { should contain 'net.ipv6.conf.default.disable_ipv6 = 1' }
    end
  end
  context 'IP v6 enabled', :unless => $ipv6_disabled do
    describe command 'ip -f inet6 a' do
      its(:stdout) { should match /inet6 [a-f0-9]+:[a-f0-9]+:[a-f0-9]+:[a-f0-9]+:[a-f0-9]+:[a-f0-9]+:(?:[a-f0-9]+:)*[a-f0-9]+\/\d+/i }
    end
    describe command "ping -c 1 #{target_host} 2>/dev/null | tr ')( ' '\\n' | grep -iE '[a-f0-9]+:[a-f0-9]+:'| head -1" do
      its(:stdout) { should match /(?:[a-f0-9]+:)*(?:[a-f0-9]+:)*(?:[a-f0-9]+:)*(?:[a-f0-9]+:)*(?:[a-f0-9]+:)*[a-f0-9]::[a-f0-9]/i }
    end
  end
  # TODO: exercise and describe '/etc/default/grub' changes
  # CARD=$(ifconfig | grep -E '^[^ ]+:' | sort | grep -v -e 'lo' -e 'docker'|awk '{print $1}')
  # echo $CARD
  # wlp1s0:

end

