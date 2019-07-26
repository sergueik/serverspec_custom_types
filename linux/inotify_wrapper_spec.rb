require 'spec_helper'
require 'fileutils'

# based on: http://www.cyberforum.ru/shell/thread2464104.html
context 'Escaping backticks and special varialbles' do
  script_path = '/tmp'
  tmp_path = '/tmp'
  script_filename = 'launch_inotify.sh'
  script = "#{script_path}/#{script_filename}"
  pipe = "#{tmp_path}/pipe"
  sample_script_data = <<-EOF
#!/bin/sh
    mkfifo #{pipe} &>/dev/null
    inotifywait --format '%f' -qme moved_to $HOME/.local/share/Trash/files -o #{pipe} &
  EOF
  before(:each) do
    $stderr.puts "Writing #{script}"
    file = File.open(script, 'w')
    file.puts sample_script_data
    file.close
    File.chmod(0755, script)
  end

  describe file script do
   it {should be_file }
   it {should be_mode 755 }
  end
  describe command( <<-EOF
    mkdir -p $HOME/.local/share/Trash/files
    #{script}
    cp /tmp/a.rb $HOME/.local/share/Trash/files
    # inotifywait --format '%f' -qme moved_from $HOME/bash/cyber/VictimovCSharp/test | while read DATA; do [ -d "$HOME/.local/share/Trash/files/$DATA" ] && echo 'DETECTED' ; done
    while read DATA; do
      [ -d "$HOME/.local/share/Trash/files/$DATA" ] && echo "$DATA moved to trash"
      break
    done <#{pipe}
    pkill inotifywait
    rm -f #{pipe}
  EOF
  ) do
   its(:exit_status) { should eq 0 }
   its(:stdout) { should contain 'moved to trash' }
   its(:stderr) { should be_empty }
  end
end

