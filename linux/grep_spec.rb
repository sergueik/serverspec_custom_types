require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

# based on: https://www.cyberforum.ru/shell/thread2600637.html
context 'chained expression grep' do
  folder = '/tmp'
  data_file = "#{folder}/a.txt"
  data = <<-EOF
    foo something
      something bar
        something else
  EOF
  before(:each) do
    $stderr.puts "Writing #{data_file}"
    file = File.open(data_file, 'w')
    file.puts (data.gsub(Regexp.new('^\s *',Regexp::MULTILINE), ''))
    file.close
  end
  describe command(<<-EOF
    grep -e '^foo ' -e ' bar$' '#{data_file}'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    [
      'foo something',
      'something bar'
    ].each do |line|
      its(:stdout) { should match Regexp.new(line, Regexp::IGNORECASE) }
    end
    its(:stdout) { should_not match Regexp.new('something else', Regexp::IGNORECASE) }
    its(:stderr) { should be_empty }
    its(:exit_status) { should eq 0 }
  end
  describe command(<<-EOF
    tee /tmp/patt.txt <<DATA
bar$
^foo
DATA
egrep -f /tmp/patt.txt '#{data_file}'
   EOF
  ) do
    its(:exit_status) { should eq 0 }
    [
      'foo something',
      'something bar'
    ].each do |line|
      its(:stdout) { should match Regexp.new(line, Regexp::IGNORECASE) }
    end
    its(:stdout) { should_not match Regexp.new('something else', Regexp::IGNORECASE) }
    its(:stderr) { should be_empty }
    its(:exit_status) { should eq 0 }
  end
end
