require 'spec_helper'
# Copyright (c) Serguei Kouzmine

$DEBUG = false

context 'Wrapping Command in Method test' do

  context 'Jar' do
    def jar_is_running(jar_name )
      commandline = "test $(ps ax | grep -v grep | grep -c '#{jar_name}') -gt 0"
      if $DEBUG
        $stderr.puts "probing #{jar_name}"
        $stderr.puts "Running command: #{commandline}"
      end
      exit_status = command(commandline).exit_status
      if $DEBUG
        $stderr.puts "Exit status:#{exit_status}"
      end
      status =
        if exit_status == 0
          true
        else
          false
        end
      status
    end

    jar_name = 'org.apache.catalina.startup.Bootstrap'
    bogus_jar_name = 'example.Main'

    it "jar #{jar_name} is running" do
      expect(jar_is_running(jar_name)).to be_truthy
    end
    it "jar #{bogus_jar_name} is not running" do
      expect(jar_is_running(bogus_jar_name)).to be_falsey
    end
  end
  context 'Arguments' do

    def jar_is_running_with_argument(jar_name, argument)
      argument.gsub!(/\-/,'\\\\-')
      commandline = "ps ax | grep '#{jar_name}' | grep -v 'grep' | sed 's|  *|\\\\n|g' | grep -q '#{argument}'"
      if $DEBUG
        $stderr.puts "probing #{jar_name} and #{argument}"
        $stderr.puts "Running command: #{commandline}"
      end
      exit_status = command(commandline).exit_status
      if $DEBUG
        $stderr.puts "Exit status:#{exit_status}"
      end
      status =
        if exit_status == 0
          true
        else
          false
        end
      status
    end

    tomcat_version_major = '7'

    # on Centos 7, installs tomcat7 into a non standard directory structure
    # sudo yum install -q -y tomcat
    # sudo /usr/sbin/tomcat start

    jar_name = 'org.apache.catalina.startup.Bootstrap'
    option_present = 'Dcatalina.base=/usr/share/tomcat'
    option_missing = 'Dcatalina.base=/opt/tomcat'
    [
      option_present,
      "-#{option_present}"
    ].each do |option|
      it "jar #{jar_name} is running with argument #{option}" do
        expect(jar_is_running_with_argument(jar_name, option)).to be_truthy
      end
    end
    [
      option_missing,
      "-#{option_missing}"
    ].each do |option|
      it "jar #{jar_name} is not running with argument #{option}" do
        expect(jar_is_running_with_argument(jar_name, option)).to be_falsey
      end
    end
  end
end


