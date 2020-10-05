if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
else
  require 'spec_helper'
end
require 'fileutils'

context 'build job inline Python script tests' do

  # NOTE: python code is indent-sensitive
  tmp_path = '/tmp'
  script = "#{tmp_path}/a.sh"
  script_data=<<-DATA
#!/bin/sh
for ARG in foo bar ;  do
  SCRIPT=/tmp/a$$.py
  
  cat <<EOF>$SCRIPT
import sys
print("argument={}".format(sys.argv[1]), file = sys.stderr)
EOF
  RESULT=$(env python3 $SCRIPT $ARG)
  echo $RESULT
done
DATA
  before(:each) do
    $stderr.puts "Writing #{script}"
    file = File.open(script, 'w')
    file.puts script_data
    file.close
    File.chmod(0755, script)

  end
  describe command(<<-EOF
    cd '#{tmp_path}'
    #{script}
  EOF

  ) do
    its(:exit_status) { should eq 0 }
    [
      'argument=foo',
      'argument=bar',
    ].each do |line|
      its(:stderr) { should contain line }
    end
  end
end
