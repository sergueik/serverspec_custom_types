require 'spec_helper'
"# Copyright (c) Serguei Kouzmine"
require 'fileutils'

# Puppet-generated cron jobs may run Ruby scripts,
# ensure the syntax of the generated script is correct
context 'Ruby Script' do
  script_path = '/tmp'
  script_filename = 'a.rb'
  script = "#{script_path}/#{script_filename}"
  sample_script_data = <<-EOF
    require 'json'
    $stderr.puts 'Done.'
  EOF

  before(:each) do
    $stderr.puts "Writing #{script}"
    file = File.open(script, 'w')
    file.puts sample_script_data
    file.close
    File.chmod(0755, script)
  end

  describe file script do
   it {should be_file }
   it {should be_mode 755 }  # 0755 => mode?(493)
  end
  describe command( <<-EOF
    ruby -c '#{script}'
  EOF
  ) do
   its(:exit_status) { should eq 0 }
   its(:stdout) { should contain 'Syntax OK' }
   its(:stderr) { should be_empty }
  end
end
