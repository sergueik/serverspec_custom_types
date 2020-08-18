require 'spec_helper'
require 'find'

$DEBUG = (ENV.fetch('DEBUG', false) =~ (/^(true|t|yes|y|1)$/i))

# https://serverfault.com/questions/48109/how-to-find-files-with-incorrect-permissions-on-unix
context 'Permission scan' do
  context 'Counting world-writable/-executable files' do
    result = true
    total_count = 0
    basedir = '/tmp'
    before(:each) do
      Specinfra::Runner::run_command( <<-EOF
        pushd #{basedir}
        touch bad1.txt
        touch bad2.txt
        chmod 746 bad1.txt
        chmod 747 bad2.txt
        1>&2 ls -l bad1.txt bad2.txt
        popd
        sleep 3
      EOF
      )
    end
    if File.exist?(basedir)
      $stderr.puts "Scanning #{basedir}"
      Find.find(basedir) do |filepath|
        unless FileTest.directory?(filepath)
          begin	
            s = File.stat(filepath)
            $stderr.puts sprintf('%s %o', filepath, s.mode )
            check = s.mode & 03
            if check != 0
              result = false
              total_count = total_count + 1
            end
          rescue => e
            $stderr.puts e.to_s
          end	
        end
      end
      $stderr.puts "Total count: #{total_count}"
      $stderr.puts ('Success: ' + result.to_s )
      it { result.should be_falsy }
      it { expect(total_count).to be >= 2  }
    else
      $stderr.puts ('Skipped missing directory ' + basedir )
    end
  end
  context 'File permissions file fix validation "unless" condition' do
    result = true
    total_count = 0
    basedir = '/tmp'
    before(:each) do
      Specinfra::Runner::run_command( <<-EOF
        pushd #{basedir}
        find . -type f -and \\( -perm /o=w -or -perm /o=x \\) -exec chmod o-wx -c {} \\;
        popd
        sleep 3
      EOF
      )
    end
    if File.exist?(basedir)
      $stderr.puts "Scanning #{basedir}"
      # NOTE: this will fail for combination of undesired permission bits detected
      perms = {
        1 => 'execute' ,
        2 => 'write',
        4 => 'read'
      }
      Find.find(basedir) do |filepath|
        unless FileTest.directory?(filepath)
          begin	
            s = File.stat(filepath)
            # read | write| execute
            # check = s.mode & 03
            # sometimes security requests an 750 "or better offer" permission on every file
            check = s.mode & 07
            if check != 0
              # msg = sprintf('%s %o %s | %d', filepath, s.mode, perms[check], check )
              msg = sprintf('%s %o %d', filepath, s.mode, check )
              $stderr.puts msg
              result = false
              total_count = total_count + 1
            end
          rescue => e
            $stderr.puts e.to_s
          end	
        end
      end
      $stderr.puts "Total count: #{total_count}"
      $stderr.puts ('Success: ' + result.to_s )
      it { result.should be_truthy }
    end
  end
  context 'simply show file attributes' do
  
    filename = 'example'
    dir = '/tmp'
    filepath = "#{dir}/#{filename}"
    before(:each) do
      Specinfra::Runner::run_command( <<-EOF
        touch '#{filepath}'
        chmod 0755 '#{filepath}'
      EOF
      )
    end
      describe command(<<-EOF
        find #{dir} -type f -exec stat -c '%a %n' {} \\;
      EOF
      ) do
        its(:stdout) { should match /755 #{filepath}/ }
      end
  end
end

# In Puppet one would possibly do it like
#
# exec { 'correct permissions':
#   command   => 'find . -type f -and \( -perm /o=w -or -perm /o=x \) -exec chmod o-wx -c {} \;'
#   path      => 'usr/bin:/bin',
#   cwd       => $applcation_directory,
#   logoutput => on_failure,
#   unless    => 'test $(find . -type f -and \( -perm /o=w -or -perm /o=x \)) -eq 0'
# }
# with an obvious modification if the file mode is required to be set to 750 obo
