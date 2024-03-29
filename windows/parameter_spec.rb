require 'spec_helper'
# Copyright (c) Serguei Kouzmine

require 'yaml'
context 'parameter test' do

  parameters = YAML.load_file(File.join(__dir__, '../../parameters/parameters.yml'))
  parameter = parameters['key']
  describe command(<<-EOF
    echo '#{parameter}'
  EOF
  ) do
     its(:stdout) { should contain parameter }
  end
end

# output:
# parameter test
#  Command "    echo 'sample value'
#    stdout
#      should contain "sample value"

