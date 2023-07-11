# https://qna.habr.com/q/789375
# Copyright (c) Serguei Kouzmine
# https://stackoverflow.com/questions/4075753/how-to-delete-a-folder-that-name-ended-with-a-dot
#  the recipe offered there does not work on Windows 8.1
#  build a full UNC-style path and put an extra slash ate the end - 
#  after 
#  rd "\\?\C:\developer\sergueik\xx\test."
# dir "\\?\C:\developer\sergueik\xx\test."
# touch test./a.txt
# $ ls test.
# a.txt
# nonly works from CMD.exe NOT PowerShell
if File.exists?( 'spec/windows_spec_helper.rb')
  require_relative '../windows_spec_helper'
end
require 'spec_helper'

# https://javatutorial.net/java-9-jshell-example
context 'when the file name is invalid in the Win32 name space' do
  context 'Basic' do
  end
end  
# 1 Create via git bash, cygwin ot wsl the directory with a trailing dot
# 2 . Observe it not listable: 
# dir test.
# dir : Cannot find path 'C:\developer\sergueik\xx\test.' because it does not exist.
#
# dir "\\?\C:\developer\sergueik\xx\test."
# Volume in drive \\?\C: is Windows8_OS
# Volume Serial Number is 60EB-344D
#
# Directory of \\?\C:\developer\sergueik\xx\test
#
#  File Not Found
#
#
#
# rd "\\?\C:\developer\sergueik\xx\test."
#
# The directory is not empty.
#  rd /s/q  "\\?\C:\developer\sergueik\xx\test."
#   works: directory and its contents is gone
