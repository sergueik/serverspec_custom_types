require 'spec_helper'
require 'find'

# List of world-writable or world-executable files in specific application directory

context 'App word writable executable files' do
  describe 'File detection' do
    $DEBUG = false
    result = true
    total_count = 0
    basedir = '/tmp'
    if $DEBUG
      basedir = ENV["HOME"]
      if basedir.nil?
        basedir = ENV["USERPROFILE"]
      end
    end
    $stderr.puts "Scanning #{basedir}"
    Find.find(basedir) do |filepath|
      unless FileTest.directory?(filepath)
        begin	
          s = File.stat(filepath)
          if (s.mode) & 03 != 0
            msg = sprintf('%s %o', filepath, s.mode )
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

    $stderr.puts result
    it { result.should be_truthy }
  end
end

# pushd /tmp; touch test.aug ; touch bad.txt; chmod 746 test.aug ;  chmod 747 bad.txt ;  popd
# ls -l   bad.txt test.aug
# -rwxr--rwx. 1 root root   0 Nov 26 22:54 bad.txt
# -rwxr--rw-. 1 root root 270 Nov 23 01:56 test.aug
# popd
# https://serverfault.com/questions/48109/how-to-find-files-with-incorrect-permissions-on-unix
# pushd /tmp ; find  . -type f -and \( -perm /o=w -or -perm /o=x \)  -exec chmod o-wx -c {} \; ; popd
# mode of ‘./bad.txt’ changed from 0747 (rwxr--rwx) to 0744 (rwxr--r--)
# mode of ‘./test.aug’ changed from 0746 (rwxr--rw-) to 0744 (rwxr--r--)
