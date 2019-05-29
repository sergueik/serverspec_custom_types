require 'spec_helper'
require 'fileutils'

context 'Puppet Exotic resource usage exercise' do
  base_dir = '/tmp'
  parent_dir = '/tmp/application'
  extra_file = 'dummy' 
  keep_version = '7'
  shell_script_file = '/tmp/example.sh'

  # for Ruby $ is not a special character, but for shell it is
  puppet_script = <<-EOF
    file { '${PARENT_DIR}':
      ensure       => directory,
      force        => true,
      purge        => true,
      backup       => false,
      recurselimit => 1,
      recurse      => true,
      ignore       => ['keep_version', '${KEEP_VERSION}', '${EXTRA_FILE}'],
    }
  EOF
  puppet_script.gsub!(/\r?\n/, '').gsub!(/\s+/ ,' ')
  shell_script = <<-EOF
#!/bin/bash
    EXTRA_FILE='#{extra_file}'
    PARENT_DIR='#{parent_dir}'
    KEEP_VERSION='#{keep_version}'
    PUPPPET_SCRIPT="#{puppet_script}"
    test -d $PARENT_DIR || mkdir $PARENT_DIR
    cd $PARENT_DIR
    touch $EXTRA_FILE
    for VERSION in 1 2 3 4 5 6 7 8 9 10 ; do
      mkdir -p "${VERSION}/stuff/inside"
    done
    ln -fs ${KEEP_VERSION} 'keep_version'
    cd #{base_dir}
    # uncomment fro interactive run
    # read -p 'Press [Enter] key to start cleanup...'
    echo puppet apply -e "${PUPPPET_SCRIPT}"
    puppet apply -e "${PUPPPET_SCRIPT}"
  EOF
  context 'wrapping ' do
    before(:each) do
      $stderr.puts "Writing #{shell_script_file}"
      file = File.open(shell_script_file, 'w')
      file.puts shell_script
      file.close
    end
    describe command( <<-EOF
      /bin/sh #{shell_script_file}
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      [
        'keep_version',
        keep_version,
      ].each do |filename|
        describe file("#{parent_dir}/#{filename}") do
          it { should exist}
        end
      end
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
      its(:stderr) { should be_empty }
      # Press [Enter] key to start cleanup...
    end
  end
  context 'version 2' do
    describe command( <<-EOF
      PARENT_DIR='#{parent_dir}'
      KEEP_VERSION='#{keep_version}'
      PUPPPET_SCRIPT="#{puppet_script}"
      EXTRA_FILE='#{extra_file}'
      test -d $PARENT_DIR || mkdir $PARENT_DIR
      cd $PARENT_DIR
      touch $EXTRA_FILE
      for VERSION in 1 2 3 4 5 6 7 8 9 10 ; do
        mkdir -p "${VERSION}/stuff/inside"
      done
      ln -fs ${KEEP_VERSION} 'keep_version'
      cd #{base_dir}
      echo puppet apply -e "${PUPPPET_SCRIPT}"
      puppet apply -e "${PUPPPET_SCRIPT}"
      find $PARENT_DIR -maxdepth 1 -type d -print
      find $PARENT_DIR -maxdepth 1 -type f -print
      find $PARENT_DIR -maxdepth 1 -type l -print
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      [
        'keep_version',
        keep_version,
      ].each do |dirname|
        describe file("#{parent_dir}/#{dirname}") do
          it { should exist}
        end
      end
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
      its(:stderr) { should be_empty }
      [
        parent_dir,
        "#{parent_dir}/#{keep_version}"
      ].each do |dirname|
        its(:stdout) { should include dirname }
      end
      [
        extra_file,
      ].each do |filename|
        its(:stdout) { should include "#{parent_dir}/#{filename}" }
      end
      [
        'keep_version',
      ].each do |filename|
        its(:stdout) { should include "#{parent_dir}/#{filename}" }
      end
      
    end
  end
end
