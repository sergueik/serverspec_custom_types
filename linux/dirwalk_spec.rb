require 'spec_helper'
require 'fileutils'


context 'release enum command' do
  before(:each) do

    %w|01 02 03 04 05|.each do |d|
      p = '/tmp/release_' + d
      unless Dir.exists?(p)
        Dir.mkdir(p)
      end
    end
    %w|01 03 05|.each do |d|
      FileUtils.mkdir_p("/tmp/release_#{d}/modules/some_module")
    end
    %w|02 04 05|.each do |d|
      FileUtils.mkdir_p("/tmp/release_#{d}/modules")
    end
  end

  describe command(<<-EOF
    cd /tmp
    DIR_TEMPLATE='release_'
    ls -1d $DIR_TEMPLATE* | while read RELEASE_DIR ; do
     # echo $RELEASE_DIR
     MODULE_DIR="$RELEASE_DIR/modules"
     if [ -d $MODULE_DIR ] ; then
      # echo "find $MODULE_DIR -maxdepth 1 -a -type d -path $MODULE_DIR -o -print"
      MODULES=$(find $MODULE_DIR -maxdepth 1 -a -type d -path $MODULE_DIR -o -print)
      if [ ! -z "$MODULES" ] ; then
        echo -e "found:\n$MODULES"
      fi
     fi
    done
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    %w|
      release_01/modules/some_module
      release_03/modules/some_module
      release_05/modules/some_module
    |.each do|module_path|
      its(:stdout) { should include "#{module_path}" }
    end
    %w|
      release_02/modules
      release_04/modules
    |.each do|module_path|
      its(:stdout) { should_not include "#{module_path}" }
    end
  end
end
