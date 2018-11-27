require 'spec_helper'
require 'find'

# https://serverfault.com/questions/48109/how-to-find-files-with-incorrect-permissions-on-unix
context 'App word writable executable files' do
  context 'Unwanted permissions file detection' do
    $DEBUG = false
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
    # NOTE: fix possible poor synchronization between `before` through sleep - not very reliable
    context 'test' do
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
      $stderr.puts "total count: #{total_count}"
      $stderr.puts result
      it { result.should be_falsy }
      it { expect(total_count).to be >= 2  }
    end
  end  
  context 'File permissions file fix validation' do
    $DEBUG = false
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
    context 'test' do
      $stderr.puts "Scanning #{basedir}"
      Find.find(basedir) do |filepath|
        unless FileTest.directory?(filepath)
          begin	
            s = File.stat(filepath)
            check = s.mode & 03
            if check != 0
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
      $stderr.puts "total count: #{total_count}"
      $stderr.puts result
      it { result.should be_truthy }
    end
  end
end

# Puppet would do it like
#
# exec { 'correct permissions':
#   command   =>  'find . -type f -and \( -perm /o=w -or -perm /o=x \) -exec chmod o-wx -c {} \;'
#   path      => 'usr/bin:/bin',
#   cwd       => $applcation_directory,
#   logoutput => on_failure,
#   unless    => 'test $(find . -type f -and \( -perm /o=w -or -perm /o=x \)) -eq 0'
# }