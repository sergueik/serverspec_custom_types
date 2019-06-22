require 'spec_helper'
require 'pp'

# expects the Puppet hieradata configuration to match
# the file hash of artifact of war installed in tomcat container
context 'Artifact hash check' do
  config_file = 'common.yaml'
  config_key = 'artifact_checksum'
  config_path = '.'
  artifact='dummy.file'
  hiera_path_check='hieradata'
  tomcat_appdir = '/opt/tomcat'
  describe command(<<-EOF
    DEBUG=
    CONFIG_PATH='#{config_path}'
    CONFIG_FILE='#{config_file}'
    CONFIG_KEY='#{config_key}'
    TOMCAT_APPDIR='#{tomcat_appdir}'
    ARTIFACT_PATH="${TOMCAT_APPDIR}/webapps"
    # TODO: read $ARTIFACT from $CONFIG_FILE
    ARTIFACT='#{artifact}'
    HIERA_PATH_CHECK='#{hiera_path_check}'
    MOUNT_ROOT=$(mount -t vboxsf | grep "${HIERA_PATH_CHECK}" | head -1 | cut -f 3 -d ' ')
    if [ ! -z $MOUNT_ROOT ]
    then
      if [ -d $MOUNT_ROOT ]
      then
        if [ ! -z $DEBUG ] ; then
          echo "Reading \\"${CONFIG_KEY}: \\" from ${MOUNT_ROOT}/${CONFIG_PATH}/${CONFIG_FILE}"
        fi
        NEEDED_HASH=$(grep "${CONFIG_KEY}: " $MOUNT_ROOT/$CONFIG_PATH/$CONFIG_FILE|head -1 | sed "s|${CONFIG_KEY}: ||"|tr -d "'"| tr -d '\\r'| tr -d ' ')
        if [ ! -z $DEBUG ] ; then
          echo running  sha256sum "${ARTIFACT_PATH}/${ARTIFACT}"
          sha256sum "${ARTIFACT_PATH}/${ARTIFACT}"
        fi
        ACTUAL_HASH=$(sha256sum "${ARTIFACT_PATH}/${ARTIFACT}" | cut -d ' ' -f 1| tr -d '\\n')
        if [ ! -z $DEBUG ] ; then
          echo "Comparing ${ACTUAL_HASH} to ${NEEDED_HASH}"
        fi
        if [ "$ACTUAL_HASH" = "$NEEDED_HASH" ]
        then
          echo 'Valid'
        else
          echo 'Invalid'
          if [ ! -z $DEBUG ] ; then
            echo "ACTUAL_HASH='$ACTUAL_HASH'"
            echo "NEEDED_HASH='$NEEDED_HASH'"
          fi
        fi
      fi
    fi
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'Valid' }
    its(:stderr) { should be_empty }
  end
end