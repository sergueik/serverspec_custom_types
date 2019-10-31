require 'spec_helper'
require 'fileutils'

# ~/.gitconfig autocrlf = false switch often cause provision errors from \r in the file resources
context 'autoclf inspection' do

  example_script_name = 'example_script.sh'
  broken_script_name = 'broken_script.sh'
  script_basedir = '/tmp'

  example_script_data=<<-EOF
    #!/usr/bin/env bash
    echo 'it works'
    exit 0
  EOF

  before(:each) do
    filepath = "#{script_basedir}/#{example_script_name}"
    $stderr.puts "Writing "#{filepath}"
    file = File.open(filepath, 'w')
    file.puts example_script_data.gsub(/\r/,'')
    file.close
    File.chmod(0755, filepath )
    filepath = "#{script_basedir}/#{broken_script_name}"
    $stderr.puts "Writing "#{filepath}"
    file = File.open(filepath, 'w')
    file.puts example_script_data.gsub!(/$/,"\r\n")
    file.close
    File.chmod(0755, filepath )
    #
  end
  describe command(<<-EOF
    #{example_script_name}
  EOF
  ) do
    let(:path) { "/bin:/usr/bin:/sbin:#{script_basedir}"}
    its(:stdout) { should contain 'it works' }
    its(:exit_status) { should eq 0 }
    its(:stderr) { should be_empty }
  end
  describe command(<<-EOF
    od -x '#{script_basedir}/#{example_script_name}'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not contain '0a0d' }
  end
  describe command(<<-EOF
    #{broken_script_name}
  EOF
  ) do
    let(:path) { "/bin:/usr/bin:/sbin:#{script_basedir}"}
    # RHEL 7
    its(:exit_status) { should eq 255 }
    its(:stderr) { should match /: (?:No such file or directory|command not found|numeric argument required)/i }
  end
  describe command(<<-EOF
    od -x '#{script_basedir}/#{broken_script_name}' | grep -P '0a0d'
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should contain '0a0d' }
  end
  describe command(<<-EOF
    DATAFILE='#{script_basedir}/#{example_script_name}'
    ORIGINAL_FILE_SIZE=$(cat $DATAFILE | wc -c)
    MODIFIED_FILE_SIZE=$(cat $DATAFILE | sed 's|\\r||g' |wc -c)
    # NOTE: one cannot use [[ in /bin/sh
    # [[: not found 
    # if [[ $MODIFIED_FILE_SIZE -eq $ORIGINAL_FILE_SIZE ]] ; then
    if [ $MODIFIED_FILE_SIZE -eq $ORIGINAL_FILE_SIZE ] ; then
      1>&2 echo "File ${DATAFILE} has Unix line endings."
      exit 0
    else
      1>&2 echo "File ${DATAFILE} has Windows line endings."
      exit 1
    fi
  EOF
  ) do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should_not contain 'not found' }
    its(:stderr) { should contain 'Unix line endings' }
  end
end
