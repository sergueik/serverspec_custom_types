require 'serverspec'

# in Windows environment 'spec_helper.rb' is usually present but unused
# 'windows_spec_helper.rb' is required by individual spec files
# setting the :backend incorrectly to exec would lead to error
# Errno::ENOENT:
#  No such file or directory - /bin/sh -c ls\ /etc/coreos/update.conf

set :backend, :cmd

RSpec.configure do |config|
  config.filter_gems_from_backtrace 'vagrant', 'vagrant-serverspec'
end
