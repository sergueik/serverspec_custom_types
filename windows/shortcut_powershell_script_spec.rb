require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'


$DEBUG = (ENV.fetch('DEBUG', 'false') =~ /^(true|t|yes|y|1)$/i)
context 'Powerhell Script in Argument Path' do

  context 'solution 1' do
    cmd_script = 'b.cmd'
    ps1_script = 'b.ps1'
    test_dir = 'test dir'
    message = 'this is a test'
    script_path = 'c:/users/' + ENV['USER']
    target_dir =  script_path + '/' + test_dir 
    dos_path =  target_dir.gsub(/\//,'\\\\')
    cmd_data = <<-EOF
      @echo OFF
      powershell.exe -noprofile -executionpolicy remotesigned "&{ . '#{dos_path}\\#{ps1_script}'}"
    EOF
    ps1_data = <<-EOF
      write-output '#{message}'
    EOF
    before(:all) do
      begin
        FileUtils.mkdir_p target_dir
      rescue => e
        puts e.to_s
      end

      begin
        File.open((script_path + '/'+ cmd_script), 'w') do |file|
          file.write(cmd_data)
        end
      rescue => e
        puts e.to_s
      end

      begin
          File.open((target_dir + '/' + ps1_script), 'w') do |file|
            file.write(ps1_data)
        end
      rescue => e
        puts e.to_s
      end
    end
    describe command(<<-END_COMMAND
      pushd '#{script_path}'
      cmd %%- /c #{cmd_script}
    END_COMMAND
    ) do
      its(:stdout) { should match Regexp.new(message, Regexp::IGNORECASE) }
      its(:exit_status) {should eq 0}
    end
  end
  context 'solution 2' do
    cmd_script = 'c.cmd'
    ps1_script = 'b.ps1'
    test_dir = 'test dir'
    message = 'this is a test'
    script_path = 'c:/users/' + ENV['USER']
    target_dir =  script_path + '/' + test_dir 
    dos_path =  target_dir.gsub(/\//,'\\\\')
    cmd_data = <<-EOF
      @echo OFF
      powershell.exe -noprofile -executionpolicy remotesigned -file "#{dos_path}\\#{ps1_script}"
    EOF
    ps1_data = <<-EOF
      write-output '#{message}'
    EOF
    before(:all) do
      begin
        FileUtils.mkdir_p target_dir
      rescue => e
        puts e.to_s
      end

      begin
        File.open((script_path + '/'+ cmd_script), 'w') do |file|
          file.write(cmd_data)
        end
      rescue => e
        puts e.to_s
      end

      begin
          File.open((target_dir + '/' + ps1_script), 'w') do |file|
            file.write(ps1_data)
        end
      rescue => e
        puts e.to_s
      end
    end
    describe command(<<-END_COMMAND
      pushd '#{script_path}'
      cmd %%- /c #{cmd_script}
    END_COMMAND
    ) do
      its(:stdout) { should match Regexp.new(message, Regexp::IGNORECASE) }
      its(:exit_status) {should eq 0}
    end
  end
end
