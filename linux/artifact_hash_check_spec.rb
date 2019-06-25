require 'spec_helper'
require 'yaml'
require 'pp'

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

# expects the Puppet hieradata configuration to match
# the file hash of artifact of some war installed in tomcat container
context 'Artifact hash check' do
  config_file = 'common.yaml'
  config_key = 'artifact_checksum'
  config_path = '.'
  artifact_filename = 'dummy.file'
  hiera_path_check='hieradata'
  tomcat_appdir = '/opt/tomcat'
  context 'Shell script' do
    describe command(<<-EOF
      DEBUG=#{$DEBUG}
      CONFIG_PATH='#{config_path}'
      CONFIG_FILE='#{config_file}'
      CONFIG_KEY='#{config_key}'
      TOMCAT_APPDIR='#{tomcat_appdir}'
      ARTIFACT_PATH="${TOMCAT_APPDIR}/webapps"
      # TODO: read $ARTIFACT from $CONFIG_FILE
      ARTIFACT_FILENAME='#{artifact_filename}'
      HIERA_PATH_CHECK='#{hiera_path_check}'
      # if the guest is launched directory in Virtual Box with Virtualbox Guest Additions enabled,
      # make shared folder using parent GUI, optionally make it AutoMount and discover by partition type
      # Vagrant will fo it for you automatically
      MOUNT_ROOT=$(mount -t vboxsf | grep "${HIERA_PATH_CHECK}" | head -1 | cut -f 3 -d ' ')
      if [ ! -z $MOUNT_ROOT ] ; then
        if [ -d $MOUNT_ROOT ] ; then
          if $DEBUG ; then
            echo "Reading \\"${CONFIG_KEY}: \\" from ${MOUNT_ROOT}/${CONFIG_PATH}/${CONFIG_FILE}"
          fi
          NEEDED_HASH=$(grep "${CONFIG_KEY}: " $MOUNT_ROOT/$CONFIG_PATH/$CONFIG_FILE|head -1 | sed "s|${CONFIG_KEY}: ||"|tr -d "'"| tr -d '\\r'| tr -d ' ')
          if $DEBUG ; then
            echo running sha256sum "${ARTIFACT_PATH}/${ARTIFACT_FILENAME}"
            sha256sum "${ARTIFACT_PATH}/${ARTIFACT_FILENAME}"
          fi
          ACTUAL_HASH=$(sha256sum "${ARTIFACT_PATH}/${ARTIFACT_FILENAME}" | cut -d ' ' -f 1| tr -d '\\n')
          if $DEBUG ; then
            echo "Comparing ${ACTUAL_HASH} to ${NEEDED_HASH}"
          fi
          if [ "$ACTUAL_HASH" = "$NEEDED_HASH" ] ; then
            echo 'Valid'
          else
            echo 'Invalid'
            if $DEBUG ; then
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
  context 'Ruby script' do
    command = ''
    output = %x(mount -t vboxsf | grep "#{hiera_path_check}" | head -1 | cut -f 3 -d ' ' | tr -d '\n')
    result = $?.success?
    if $DEBUG
      $stderr.puts ('output : "' + output + '"')
      # no implicit conversion of true into String
      # $stderr.puts ('result = ' + result )
    end
    basedir = '/tmp/vagrant-puppet/hieradata'
    basedir = output
    context 'Hashes check' do
      result = true
      artifact_checksum = nil
      artifact_filename = nil
      if File.exist?(basedir)
        begin	
          @res = File.open( "#{basedir}/./common.yaml") { |f| YAML::load(f ) }
          if $DEBUG
            $stderr.puts 'configuration: '
            PP.pp(@res, $stderr)
          end
          artifact_checksum = @res['artifact_checksum']
          artifact_filename = @res['artifact_filename']
          # no implicit conversion of nil into String
          if $DEBUG
            $stderr.puts ('Artifact_filename = '  + artifact_filename)
            $stderr.puts "Artifact checksum = #{artifact_checksum}"
          end
        rescue => e
          $stderr.puts e.to_s
          result = false
        end	
        output = %x(sha256sum "#{tomcat_appdir}/webapps/#{artifact_filename}" | cut -d ' ' -f 1| tr -d '\n')
        if $DEBUG
          # result = $?.success?
          $stderr.puts ('output : "' + output + '"')
        end
        actual_checksum = output
        if actual_checksum.eql? artifact_checksum
          result = true
          $stderr.puts ('Valid : "' + artifact_filename + '"')
        else
          result = false
        end
        $stderr.puts ('Success: ' + result.to_s )
      end
      it { artifact_checksum.should_not be_nil }
      it { result.should be_truthy }
    end
  end
end

# see also: https://habr.com/ru/post/251529/