require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'jq' do

  context 'availability' do
    describe command('which jq') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match Regexp.new('/bin/jq', Regexp::IGNORECASE) }
      its(:stderr) { should be_empty }
    end
  end
  context 'JSON validation' do
    tmp_path = '/tmp'
    outputfile = "#{tmp_path}/output.json"
    context 'Good JSON' do
      datafile = "#{tmp_path}/good.json"
      data = <<-EOF
       {
        "data": [
         {"row": 1}
        ],
        "config": {
          "row": {
            "hide": false
          }
        }
      }	
      EOF
      before(:each) do
        $stderr.puts "Writing #{datafile}"
        file = File.open(datafile, 'w')
        file.puts data
        file.close
      end
      describe command(<<-EOF
        jq -c '.' '#{datafile}' | tee #{outputfile}
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stderr) { should be_empty }
        describe file outputfile do
          its(:size) { should > 0 }
        end
      end
    end
    context 'Bad JSON' do
      # create a failing test, jq is in charge
      datafile = "#{tmp_path}/bad.json"
      data = <<-EOF
        {
        "data": [
           {"row": 1}
          ],
          "config": {"row": {"hide": false}
          }
      EOF
      before(:each) do
        $stderr.puts "Writing #{datafile}"
        file = File.open(datafile, 'w')
        file.puts data
        file.close
      end
      describe command(<<-EOF
        jq -c '.' '#{datafile}' | tee '#{outputfile}'
      EOF
      ) do
        its(:exit_status) { should eq 0 }
        its(:stderr) { should be_empty }
        describe file outputfile do
          its(:size) { should = 0 }
        end
      end
      describe command(<<-EOF
        pushd '#{tmp_path}' 1>/dev/null 2>/dev/null
        echo $?
        popd 1>/dev/null 2>/dev/null
        echo $?
        # 127
      EOF
      ) do
          its(:exit_status) { should eq 0 }
      end
    end
  end
  context 'querying JSON' do

    datafile = '/tmp/sample.json'

    before(:each) do
      Specinfra::Runner::run_command( <<-EOF
        cat <<END>#{datafile}
{
"code": 401
}
END
       EOF
      )
    end

    describe command(<<-EOF
      DATA_FILE='#{datafile}'
      jq -r '.code' < ${DATA_FILE}
    EOF
    ) do
      its(:stdout) { should contain '401' }
      its(:stderr) { should be_empty }
    end
  end
  context 'Generating JSON' do

    # https://toster.ru/q/608027
    # https://jqplay.org/
    # https://programminghistorian.org/en/lessons/json-and-jq
    # https://stackoverflow.com/questions/22434290/jq-bash-cake-json-array-from-variable
    # https://stedolan.github.io/jq/manual/
    datafile = '/tmp/sample.json'
    value = 'some data'
    context 'Simple' do
      before(:each) do
        Specinfra::Runner::run_command( <<-EOF
          VAL='#{value}'
          DATA_FILE='#{datafile}'
          # filling the template
          jq -n --arg val "$VAL" '{"key": $val}' | tee $DATA_FILE
        EOF
        )
      end

      describe command(<<-EOF

        DATA_FILE='#{datafile}'
        jq -r '.key' < ${DATA_FILE}

      EOF
      ) do
        its(:stdout) { should contain value }
        its(:stderr) { should be_empty }
      end
    end
    context 'Array Hacks' do
      before(:each) do
        Specinfra::Runner::run_command( <<-EOF
          VALUE="data,more data,#{value},yet more data"
          DATA_FILE='#{datafile}'
          # filling the array value in the template indirectly
          jq -Rn --arg val  "$VALUE" '{"key": $val | split(",") }' | tee $DATA_FILE
        EOF
        )
      end
      describe command(<<-EOF

        DATA_FILE='#{datafile}'
        jq -r '.key[2]' < ${DATA_FILE}

      EOF
      ) do
        its(:stdout) { should contain value }
        its(:stderr) { should be_empty }
      end
      describe command(<<-EOF
        echo -e "data,more data,#{value},yet more data" | sed 's|,|\\n|g' | jq -R . | jq -s '{"key": .}' |jq '.key[2]'
      EOF
      ) do
        its(:stdout) { should contain value }
        its(:stderr) { should be_empty }
      end
    end

    describe command(<<-EOF
      VALUE='{"val":"#{value}"}'; jq -n --argjson val "$VALUE" '{"key": $val }' | jq '.key.val'
    EOF
    ) do
      its(:stdout) { should contain value }
      its(:stderr) { should be_empty }
    end

    describe command(<<-EOF
    VALUE='{"val":["stuff","#{value}","other stuff"]}'; jq -n --argjson val "$VALUE" '{"key": $val }' | jq '.key.val[1]'
    EOF
    ) do
      its(:stdout) { should contain value }
      its(:stderr) { should be_empty }
    end
  end
  context 'Converting metric sets into JSON' do
    context 'Temp script' do
      # NOTE: do not use | as a separator
      shell_script = '/tmp/a.sh'
      shell_script_content = <<-EOF
        #!/bin/bash
        DATA_FILE1="/tmp/data1.$$"
        # NOTE: no leading whitespace
        cat<<DATA>$DATA_FILE1
first:11:second:12:third:13
first:22:second:22:third:23
first:32:second:32:third:33
DATA
        DATA_FILE2="/tmp/data2.$$"

        IFS=':'; cat $DATA_FILE1| while read KEY1 VALUE1 KEY2 VALUE2 KEY3 VALUE3; do
        jq --arg k1 "$KEY1"   \\
           --arg v1 "$VALUE1" \\
           --arg k2 "$KEY2"   \\
           --arg v2 "$VALUE2" \\
           --arg k3 "$KEY3"   \\
           --arg v3 "$VALUE3" \\
           '. | .[$k1]=$v1 | .[$k2]=$v2 | .[$k3]=$v3'  \\
           <<<'{}' ;
        done > $DATA_FILE2

        cat $DATA_FILE2 | jq --slurp '.'
        rm -f $DATA_FILE1
        rm -f $DATA_FILE2
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
        DATA_FILE1="/tmp/data1.$$"
        # NOTE: heredoc should have no leading whitespace
        cat<<DATA>$DATA_FILE1
first:11:second:12:third:13
first:21:second:22:third:23
first:31:second:32:third:33
DATA
        DATA_FILE2="/tmp/data2.$$"

        IFS=':'
        cat $DATA_FILE1 | \\
        while read KEY1 VALUE1 KEY2 VALUE2 KEY3 VALUE3
        do
          echo '{}' | \\
          jq --arg k1 "$KEY1" --arg v1 "$VALUE1" --arg k2 "$KEY2" --arg v2 "$VALUE2" --arg k3 "$KEY3" --arg v3 "$VALUE3" \\
          '. | .[$k1]=$v1 | .[$k2]=$v2 | .[$k3]=$v3'
        done > $DATA_FILE2
        cat $DATA_FILE2 | jq --slurp '.'
        RESULT_FILE="/tmp/data.$$.json"
        DATA_KEY='data'
        # making the rowset keyed by $DATA_KEY
        # TODO: explore alternatives
        cat $DATA_FILE2 | jq --slurp '.' | jq "{\\"$DATA_KEY\\": .}" | tee $RESULT_FILE
        # NOTE: passing key name as argument in the following does not work
        # jq --arg data_key "$DATA_KEY" '{ .[$data_key] =. }'

        jq '.data|.[]|.first' $RESULT_FILE
        rm -f $DATA_FILE1
        rm -f $DATA_FILE2
        rm -f $RESULT_FILE
      EOF
      ) do
        %w|11 21 31|.each do |value|
          its(:stdout) { should match Regexp.new("\"#{value}\"") }
        end
        its(:stderr) { should be_empty }
      end
    end
  end
end
