require 'spec_helper'

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
      DATAFILE='#{datafile}'
      jq -r '.code' < ${DATAFILE}
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
          DATAFILE='#{datafile}'
          # filling the template
          jq -n --arg val "$VAL" '{"key": $val}' | tee $DATAFILE
        EOF
        )
      end

      describe command(<<-EOF

        DATAFILE='#{datafile}'
        jq -r '.key' < ${DATAFILE}

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
          DATAFILE='#{datafile}'
          # filling the array value in the template indirectly
          jq -Rn --arg val  "$VALUE" '{"key": $val | split(",") }' | tee $DATAFILE
        EOF
        )
      end
      describe command(<<-EOF

        DATAFILE='#{datafile}'
        jq -r '.key[2]' < ${DATAFILE}

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
end
