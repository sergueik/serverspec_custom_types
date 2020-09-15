require 'spec_helper'
require 'fileutils'

context 'Puppet file permission change exercise' do

  context 'Purge' do
    base_dir = '/tmp'
    parent_dir = '/tmp/application'
    softlink_dir = '/tmp/linkdir'
    extra_file = 'dummy'
    keep_version = '7'
    shell_script_file = '/tmp/example_purge.sh'

    # for Ruby $ is not a special character, but for shell it is
    puppet_script = <<-EOF
      file { 'change perms in ${TARGET_DIR}':
        path         => '${TARGET_DIR}',
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
      
      test -d $PARENT_DIR || mkdir $PARENT_DIR
      cd $PARENT_DIR
      touch $EXTRA_FILE
      for VERSION in 1 2 3 4 5 6 7 8 9 10 ; do
        mkdir -p "${VERSION}/stuff/inside"
      done
      ln -fs ${KEEP_VERSION} 'keep_version'
      cd #{base_dir}
      # uncomment for interactive run
      # read -p 'Press [Enter] key to start cleanup...'
      TARGET_DIR=$PARENT_DIR
      PUPPPET_SCRIPT="#{puppet_script}"
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
  end
  context 'Apache style permission mask' do
    # see: https://puppet.com/docs/puppet/6.17/types/file.html#file-attribute-mode
    # security reuirement
    # clear all rwx from certain directories (e.g. tomcat catalina)
    base_dir = '/tmp'
    parent_dir = '/tmp/application'
    softlink_dir = '/tmp/linkdir'
    extra_file = 'dummy'
    keep_version = '7'
    shell_script_file = '/tmp/example_perm.sh'
    permissions = 'u+rwx,g-w+rX,o-rwx'
    puppet_script = <<-EOF
      file { 'change folder permissions in ${TARGET_DIR}':
        path    => '${TARGET_DIR}',
        ensure  => directory,
        recurse => true,
        mode    => '#{permissions}',
      }
    EOF
    puppet_script.gsub!(/\r?\n/, '').gsub!(/\s+/ ,' ')
    shell_script = <<-EOF
  #!/bin/bash
      EXTRA_FILE='#{extra_file}'
      PARENT_DIR='#{parent_dir}'
      KEEP_VERSION='#{keep_version}'
      test -d $PARENT_DIR || mkdir $PARENT_DIR
      cd $PARENT_DIR
      touch $EXTRA_FILE
      for VERSION in 1 2 3 4 5 6 7 8 9 10 ; do
        mkdir -p "${VERSION}/stuff/inside"
      done
      ln -fs ${KEEP_VERSION} 'keep_version'
      cd #{base_dir}
      # uncomment for interactive run
      # read -p 'Press [Enter] key to start cleanup...'
      TARGET_DIR=$PARENT_DIR
      TARGET_DIR=$PARENT_DIR
      PUPPPET_SCRIPT="#{puppet_script}"
      echo puppet apply -e "${PUPPPET_SCRIPT}"
      puppet apply -e "${PUPPPET_SCRIPT}"
      find ${TAGRET_DIR} -type d -exec stat -c '%a %n' {} \\;
    EOF
    context 'wrapping ' do
      before(:each) do
        $stderr.puts "Writing #{shell_script_file}"
        file = File.open(shell_script_file, 'w')
        file.puts shell_script        
        file.close
        File.chmod(0755, shell_script_file)
      end
      describe command( shell_script_file  ) do
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
        its(:stdout) { should_not contain /^75[^0] .*$/ }
      end
    end    
  end
end

