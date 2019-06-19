require 'serverspec'
# on Windows 'spec_helper.rb' is ignored in favor of 'windows_spec_helper.rb'
# but the :backend setting value is cloned from 'windows_spec_helper.rb'

set :backend, :cmd
