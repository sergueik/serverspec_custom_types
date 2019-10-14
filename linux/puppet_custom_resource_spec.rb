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
  context 'inspection' do
    puppet_script.gsub!(/\r?\n/, '')
    describe command( <<-EOF
      PARENT_DIR='#{parent_dir}'
      KEEP_VERSION='#{keep_version}'
      PUPPPET_SCRIPT="#{puppet_script}"
      test -d $PARENT_DIR || mkdir $PARENT_DIR
      cd $PARENT_DIR
      for VERSION in 1 2 3 4 5 6 7 8 9 10 ; do 
        mkdir -p "${VERSION}/stuff/inside"
      done
      cd #{base_dir}
      echo puppet apply -e "${PUPPPET_SCRIPT}"
      puppet apply -e "${PUPPPET_SCRIPT}"
    EOF
    ) do
      its(:exit_status) { should eq 0 }
      [
      'keep_version',
      keep_version,
      ].each do |text|
        # its(:stdout) { should match Regexp.new("\\b#{text}\\b", Regexp::IGNORECASE) }
      end
      let(:path) { '/bin:/usr/bin:/sbin:/opt/puppetlabs/puppet/bin'}
      # Failed to load feature test for microsoft_windows: ERROR: Failed to build gem native extension
      # logged to /root/.gem/ruby/2.1.0/extensions/x86_64-linux/2.1.0/nokogiri-1.8.1/gem_make.out
      # its(:stderr) { should be_empty }
    end
  end
end

