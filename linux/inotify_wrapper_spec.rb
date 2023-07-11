require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

# based on: http://www.cyberforum.ru/shell/thread2464104.html
# see also: https://mnorin.com/inotify-v-bash.html
# see also: https://habr.com/ru/post/66569/
# for Windows port, see
# https://docs.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher?redirectedfrom=MSDN&view=netframework-4.5.1
# https://github.com/thekid/inotify-win
context 'Inotify output processing' do
  script_path = '/tmp'
  tmp_path = '/tmp'
  trash_filder_path = ""
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
    SAMLE_FILE="/tmp/a.$$"
    TRASH_FOLDER=$HOME/.local/share/Trash/files
    touch $SAMLE_FILE
    cp $SAMLE_FILE $TRASH_FOLDER
    # inotifywait --format '%f' -qme moved_from $HOME/bash/cyber/VictimovCSharp/test | while read DATA; do [ -d "$HOME/.local/share/Trash/files/$DATA" ] && echo 'DETECTED' ; done
    while read DATA; do
      if [ -f "${TRASH_FOLDER}/${DATA}" ] ; then
        echo "$DATA just moved to trash folder"
        break
      fi
    done <#{pipe}
    pkill inotifywait
    rm -f #{pipe}
  EOF
  ) do
   its(:exit_status) { should eq 0 }
   its(:stdout) { should contain 'just moved to trash folder' }
   its(:stderr) { should be_empty }
  end
end

