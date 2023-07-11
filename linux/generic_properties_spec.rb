require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

# examine configuration file, e.g. desktop application launcher
# confirm that it has specific entries in a specific section using plain sed
context 'Parsing configuration' do
  basedir = '/tmp'
  datafile = "#{basedir}/file.txt"
  key1 = 'key one'
  key2 = 'key two'
  sample_data = <<-EOF
[#{key1}]
  key1=one 1
  key2=one 2
[#{key2}]
  key1=two 1

  EOF
  before(:each) do
    $stderr.puts "Writing #{datafile}"
    file = File.open(datafile, 'w')
    file.puts sample_data
    file.close
  end

  context 'inspection' do
    describe command( <<-EOF
      cd #{basedir}
      sed -rn '/\\[#{key1}\\]/,/^\\[/p' #{datafile}
    EOF
    ) do
      let(:path) {'/bin:/usr/bin'}
      its(:stderr) { should be_empty }
      [
        'one 1',
        'one 2',
        'dummy to debug the output'
      ].each do |value|
        its(:stdout) { should contain '=' + value }
      end
      its(:exit_status) {should eq 0 }
      [
        'two 1',
        'two 2'
      ].each do |value|
        its(:stdout) { should_not contain '=' + value }
      end
    end
  end
end
