require 'serverspec'
# This winsows_spec_helper.rb is for running serverspec locally on a Windows box


set :backend, :cmd
# 'spec_helper.rb' is usually present but unused in Windows testing
# by require 'windows_spec_helper.rb' in each individual spec files
# setting the :backend incorrectly to :exec would manifest through error
# Errno::ENOENT:
# No such file or directory - /bin/sh -c ls\ /etc/coreos/update.conf

RSpec.configure do |config|
  config.filter_gems_from_backtrace 'vagrant', 'vagrant-serverspec'
end
