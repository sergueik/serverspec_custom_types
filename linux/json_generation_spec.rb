require 'spec_helper'

context 'Converting metric sets into JSON' do
  context 'Temp script' do
    # NOTE: do not use | as a separator
    shell_script = '/tmp/a.sh'
    shell_script_content = <<-EOF
      #!/bin/bash
      DATAFILE1="/tmp/data1.$$"
      # NOTE: no leading whitespace
      cat<<DATA>$DATAFILE1
first:11:second:12:third:13
first:22:second:22:third:23
first:32:second:32:third:33
DATA
      DATAFILE2="/tmp/data2.$$"

      IFS=':'; cat $DATAFILE1| while read KEY1 VALUE1 KEY2 VALUE2 KEY3 VALUE3; do
      jq --arg k1 "$KEY1"   \\
         --arg v1 "$VALUE1" \\
         --arg k2 "$KEY2"   \\
         --arg v2 "$VALUE2" \\
         --arg k3 "$KEY3"   \\
         --arg v3 "$VALUE3" \\
         '. | .[$k1]=$v1 | .[$k2]=$v2 | .[$k3]=$v3'  \\
         <<<'{}' ;
      done > $DATAFILE2

      cat $DATAFILE2 | jq --slurp '.'
      rm -f $DATAFILE1
      rm -f $DATAFILE2
    EOF
    before(:each) do
      $stderr.puts "Writing #{shell_script}"
      file = File.open(shell_script, 'w')
      file.puts shell_script_content.strip
      file.close
      File.chmod(0755, shell_script)
    end
    # /bin/sh: error while loading shared libraries: libc.so.6: cannot open shared object file: Error 24\
    describe command(<<-EOF
      /bin/bash #{shell_script} | tee /tmp/a.log
    EOF
    ) do
      its(:stdout) { should match Regexp.new('"first": "11"') }
      its(:stderr) { should be_empty }
    end
  end
  context 'Inline script' do
    # NOTE: when run a inline script the line
    # <<<'{}'
    # leads to
    # 8: Syntax error: redirection unexpected
    describe command(<<-EOF
      #!/bin/bash
      DATAFILE1="/tmp/data1.$$"
      # NOTE: no leading whitespace
      cat<<DATA>$DATAFILE1
first:11:second:12:third:13
first:21:second:22:third:23
first:31:second:32:third:33
DATA
      DATAFILE2="/tmp/data2.$$"

      IFS=':'
      cat $DATAFILE1 | \\
      while read KEY1 VALUE1 KEY2 VALUE2 KEY3 VALUE3
      do
  # echo "KEY1=${KEY1}"
  # echo "VALUE1=${VALUE1}"
  # echo "KEY2=${KEY2}"
  # echo "VALUE2=${VALUE1}"
  # echo "KEY3=${KEY3}"
  # echo "VALUE3=${VALUE3}"
        echo '{}' | \\
        jq --arg k1 "$KEY1" --arg v1 "$VALUE1" --arg k2 "$KEY2" --arg v2 "$VALUE2" --arg k3 "$KEY3" --arg v3 "$VALUE3" \\
        '. | .[$k1]=$v1 | .[$k2]=$v2 | .[$k3]=$v3'
      done > $DATAFILE2
      cat $DATAFILE2 | jq --slurp '.'
      # rm -f $DATAFILE1
      # rm -f $DATAFILE2
    EOF
    ) do
      its(:stdout) { should match Regexp.new('"second": "32"') }
      its(:stderr) { should be_empty }
    end
  end
end
