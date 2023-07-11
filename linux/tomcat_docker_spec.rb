require 'spec_helper'
# Copyright (c) Serguei Kouzmine
# require docker'
# based on https://github.com/apolloclark/packer-elk-docker/blob/master/tomcat/spec/Dockerfile_spec.rb
# uses RSpec 3.x syntax

context 'Tomcat' do

  def os_version
    command('uname -a').stdout
  end

  def current_user
    command('whoami').stdout.strip
  end

  def tomcat_version_command_output
    # NOTE: move into the def scope from the top, or not visible
    catalina_home = '/usr/share/tomcat'
    command("java -cp #{catalina_home}/lib/catalina.jar org.apache.catalina.util.ServerInfo").stdout
  end

  # reasonabe for Docker provisioner
  it 'installs the right version of linux' do
    expect(os_version).to include 'GNU/Linux'
  end

  tomcat_version_major = '7'
  it 'tomcat version' do
    # NOTE: :include needs a full line verbatim
    expect(tomcat_version_command_output).to include 'Server version: Apache Tomcat/7.0.76'
    expect(tomcat_version_command_output).to contain "Apache Tomcat/#{tomcat_version_major}\..*$"
  end

  describe user('tomcat') do
    it { should exist }
    # ubuntu-specific
    xit { should have_uid 1001 }
    it { should belong_to_group 'tomcat' }
    it { should have_login_shell '/sbin/nologin' }
  end

  describe group('tomcat') do
    it {should exist}
    # ubuntu-specific
    xit { should have_gid 1000}
  end
end