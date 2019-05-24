require 'spec_helper'
require 'fileutils'

context 'Puppet Exotic resource usage exercise' do
  base_dir = '/tmp'
  parent_dir = '/tmp/application'
  keep_version = '7'

  # for Ruby $ is not a special character, but for shell it is
  puppet_script = <<-EOF
    file { '${PARENT_DIR}':
      ensure       => directory,
      force        => true,
      purge        => true,
      backup       => false,
      recurselimit => 1,
      recurse      => true,
      ignore       => ['keep_version', '${KEEP_VERSION}'],
    }

  EOF
  puppet_script.gsub!(/\r?\n/, '').gsub!(/\s+/ ,' ')
  shell_script = <<-EOF
    PARENT_DIR='#{parent_dir}'
    KEEP_VERSION='#{keep_version}'
    PUPPPET_SCRIPT="#{puppet_script}"
    test -d $PARENT_DIR || mkdir $PARENT_DIR
    cd $PARENT_DIR
    for VERSION in 1 2 3 4 5 6 7 8 9 10 ; do
      mkdir -p "${VERSION}/stuff/inside"
    done
    ln -fs ${KEEP_VERSION} 'keep_version'
    cd #{base_dir}
    if [ ! -z $URU_INVOKER ] ; then
      echo "Protecting Puppet from uru environment"
      mv /root/.gem/ /root/.gem.MOVED
    fi
    echo puppet apply -e "${PUPPPET_SCRIPT}"
    puppet apply -e "${PUPPPET_SCRIPT}"
    if [ ! -z $URU_INVOKER ] ; then
      echo "Restoring uru environment"
      mv /root/.gem.MOVED /root/.gem
    fi
  EOF
  shell_script_file = '/tmp/example.sh'
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
    end
  end
  context 'version 2' do
    describe command( <<-EOF
      PARENT_DIR='#{parent_dir}'
      KEEP_VERSION='#{keep_version}'
      PUPPPET_SCRIPT="#{puppet_script}"
      test -d $PARENT_DIR || mkdir $PARENT_DIR
      cd $PARENT_DIR
      for VERSION in 1 2 3 4 5 6 7 8 9 10 ; do
        mkdir -p "${VERSION}/stuff/inside"
      done
      ln -fs ${KEEP_VERSION} 'keep_version'
      cd #{base_dir}
      if [ ! -z $URU_INVOKER ] ; then
        echo "Protecting Puppet from uru environment"
        mv /root/.gem/ /root/.gem.MOVED
      fi
      echo puppet apply -e "${PUPPPET_SCRIPT}"
      puppet apply -e "${PUPPPET_SCRIPT}"
      if [ ! -z $URU_INVOKER ] ; then
        echo "Restoring uru environment"
        mv /root/.gem.MOVED /root/.gem
      fi
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
    end
  end
end
