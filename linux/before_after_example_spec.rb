# encoding: utf-8
# Copyright (c) Serguei Kouzmine

require 'spec_helper'
require 'fileutils'

# based on: https://github.com/volanja/ansible_spec/blob/master/spec/commands_spec.rb
$DEBUG = true
$CLEAN = if ENV.fetch('CLEAN', false) =~ (/^(true|t|yes|y|1)$/i)
           true   
         else
           false
         end

context 'Before/After commands' do

  parent_dir = '/tmp/data'
  test_dirs = %w|dir_1 dir_2 dir_3 dir_4|
  test_files = []

  logfile = '/tmp/runner.log'

  before(:all) do
    begin
      $stdout = File.open('/dev/null', 'w') 
      FileUtils.mkdir_p(parent_dir) unless FileTest.exist?(parent_dir)
      Dir.chdir(parent_dir)
      test_dirs.each {|d| FileUtils.mkdir_p(d) unless FileTest.exist?(d) }
    rescue => e
      $stderr.puts "Exception (ignored): #{e}"
    end
    # Exception `IO::EAGAINWaitReadable' at <internal:prelude>:74 - Resource temporarily unavailable - read would block
    # Exception `EOFError' at <internal:prelude>:74 - end of file reached
  end
  context 'Listing' do
    describe command(<<-EOF
      cd '#{parent_dir}' > /dev/null
      ls -1dtr dir_* | tr '\\n' ' '
    EOF
    ) do
      its(:stdout) { should match Regexp.new(test_dirs.reverse().join(' ')) }
      its(:stderr) { should be_empty }
      its(:exit_status) {should eq 0 }
    end
  end

  after(:all) do
    $stderr.puts "CLEAN=#{$CLEAN}"
    begin
      if $CLEAN
        test_files.each {|f| File.delete(f) }
        test_dirs.each {|d| Dir.delete(d) }
        Dir.chdir(parent_dir)
        FileUtils.remove_entry_secure(parent_dir)
      end
      $stdout = STDOUT
    rescue => e
      $stderr.puts "Exception (ignored): #{e}"
    end
  end
end
