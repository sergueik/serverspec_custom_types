require 'spec_helper'
# Copyright (c) Serguei Kouzmine
require 'fileutils'

context 'Puppet fixup exec dry run test' do
  shell_script_file = '/tmp/example.sh'
  context 'version 1 test' do
    puppet_script = <<-EOF
      $wrong_user = 'root' # some account
      $correct_user = 'some_account' # another account

      $files = ['/tmp/a.txt', '/tmp/b.txt', '/tmp/c.txt']
      exec { "Mass cleanup of files (${files})":
        command => "echo fixing ${files}",
        path    => '/bin',
        onlyif  => "stat ${files} | sed -n '/Uid/s|^.*\\\\(Uid: ([^)]*) \\\\).*\\$|\\\\1|p'| grep -q '${wrong_user}'",
      }
    EOF
    puppet_script.gsub!(/\r?\n/, '').gsub!(/\s+/ ,' ')
    shell_script = <<-EOF
#!/bin/bash
    PUPPPET_SCRIPT="#{puppet_script}"
    echo puppet apply -e "${PUPPPET_SCRIPT}"
    puppet apply -e "${PUPPPET_SCRIPT}"
    EOF
    before(:each) do
      $stderr.puts "Writing #{shell_script_file}"
      file = File.open(shell_script_file, 'w')
      file.puts shell_script
      file.close
    end
    describe command( <<-EOF
      /bin/sh #{shell_script_file}
    EOF
    ) do
      its(:exit_status) { should eq 0 }
    end
  end
  context 'version 2 test' do
    puppet_script = <<-EOF
      $wrong_user = 'root' # some account
      $correct_user = 'some_account' # another account

      $files = ['/tmp/a.txt', '/tmp/b.txt', '/tmp/c.txt']
      exec { "Mass cleanup of files (${files})":
        command => "echo fixing ${files}",
        path    => '/bin',
        unless  => "stat ${files} | sed -n '/Uid/s|^.*Uid: (\\\\([^)]*\\\\)) .*\\$|\\\\1|p'  grep -vq '${correct_user}'",
      }
    EOF
    puppet_script.gsub!(/\r?\n/, '').gsub!(/\s+/ ,' ')
    shell_script = <<-EOF
#!/bin/bash
    PUPPPET_SCRIPT="#{puppet_script}"
    echo puppet apply -e "${PUPPPET_SCRIPT}"
    puppet apply -e "${PUPPPET_SCRIPT}"
    EOF
    before(:each) do
      $stderr.puts "Writing #{shell_script_file}"
      file = File.open(shell_script_file, 'w')
      file.puts shell_script
      file.close
    end
    describe command( <<-EOF
      /bin/sh #{shell_script_file}
    EOF
    ) do
      its(:exit_status) { should eq 0 }
    end
  end
end

# $wrong_user = 'root'
# $correct_user = 'some_account'
# $files = ['/tmp/a.txt', '/tmp/b.txt', '/tmp/c.txt']
# exec { "Mass cleanup of files (${files})":
#   path => '/bin',
#   command => "stat ${files} | sed -n '/Uid/s|^.*Uid: (\\([^)]*\\)) .*\$|\\1|p' | grep -vq '${correct_user}'",
# }
# 
#
# # #!/bin/bash
#       PUPPPET_SCRIPT=" \$wrong_user = 'root'; \$correct_user = 'some_account'; \$files = ['/tmp/a.txt', '/tmp/b.txt', '/tmp/c.txt']; exec { \"Mass cleanup of files (\${files})\": path => '/bin', command => \"stat \${files} | sed -n '/Uid/s|^.*Uid: (\\\\([^)]*\\\\)) .*\\$|\\\\1|p' grep -vq '\${correct_user}'\", };"
#       echo puppet apply -e "\"${PUPPPET_SCRIPT}\""
#       puppet apply -e "${PUPPPET_SCRIPT}"
# ~
# 
