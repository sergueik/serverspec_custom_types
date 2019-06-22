require 'spec_helper'
require 'pp'

context 'Artifact hash check' do
  describe command(<<-EOF
    CONFIG_PATH='.'
    CONFIG_FILE='common.yaml'
    TOMCAT_APPDIR='/opt/tomcat'
    ARTIFACT_PATH="${TOMCAT_APPDIR}/webapps"
    # TODO:  read $ARTIFACT from $CONFIG_FILE
    ARTIFACT='dummy.file'
    MOUNT_ROOT=$(mount -t vboxsf | grep hieradata | head -1 | cut -f 3 -d ' ')
    CONFIG_KEY='artifact_checksum'
    if [[ ! -z $MOUNT_ROOT ]]
    then
      if [[ -d $MOUNT_ROOT ]]
      then
        echo "Reading \"${CONFIG_KEY}: \" from ${MOUNT_ROOT}/${CONFIG_PATH}/${CONFIG_FILE}"
        ARTIFACT_HASH=$(grep "${CONFIG_KEY}: " $MOUNT_ROOT/$CONFIG_PATH/$CONFIG_FILE | cut -f 2 -d ':' | sed "s/'//g")
        echo running  sha256sum "${ARTIFACT_PATH}/${ARTIFACT}"

        sha256sum "${ARTIFACT_PATH}/${ARTIFACT}"
        ACTUAL_HASH=$(sha256sum "${ARTIFACT_PATH}/${ARTIFACT}" | cut -d ' ' -f 1| sed 's/\n//'| sed 's/ *//g')
        echo "Comparing ${ACTUAL_HASH} to ${ARTIFACT_HASH}"
        if [[ "$ACTUAL_HASH" = "$ARTIFACT_HASH" ]]
        then
          echo 'Valid'
        else
          echo 'Invalid'
          echo "ACTUAL_HASH='$ACTUAL_HASH'   "
          echo  "ARTIFACT_HASH='$ARTIFACT_HASH'   "
        fi
      fi
    fi
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain 'Valid`' }
    its(:stderr) { should be_empty }
  end
end