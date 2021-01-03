require_relative '../windows_spec_helper'

# NOTE: sporadicaly hanging with high CPU on Windows 8.1 / Ruby 2.3.3
# http://stackoverflow.com/questions/258701/how-can-i-get-a-list-of-all-open-named-pipes-in-windows
context 'Pipes' do
  context 'Audacity Scripting Automation Module' do
    describe process 'audacity.exe' do
      it { should be_running }
    end
    # NOTE: not 'USERNAME'
    describe file "C:\\Users\\" + ENV['USER'] + "\\AppData\\Roaming\\Audacity\\audacity.cfg"	do
      it {  should be_file }
	    its (:content) { should contain 'mod-script-pipe=1' }
    end
    named_pipes = %w|
      \\\\\\\\.\\\\pipe\\\\FromSrvPipe
      \\\\\\\\.\\\\pipe\\\\ToSrvPipe
    |
    # NOTE: GetFiles acccepts doubled backslashes:
    describe command(<<-EOF
      [System.IO.Directory]::GetFiles('\\\\.\\pipe\\') | where-object { $_ -match 'ToSrvPipe' -or $_ -match 'FromSrvPipe'}
    EOF
    ) do
      named_pipes.each do |named_pipe|
        its (:stdout) { should contain named_pipe }
      end
    end	
  end
  context 'Core' do
    # NOTE: commenting lines only work with arrays
    named_pipes = [
      '//./pipe/atsvc',
      '//./pipe/browser',
      '//./pipe/eventlog',
      '//./pipe/lsass',
      '//./pipe/ntsvcs',
      # print service will likely be disabled
      # //./pipe/spoolss',
      '//./pipe/wkssvc'
    ]
    describe command(<<-EOF
      [String[]]$pipes = [System.IO.Directory]::GetFiles('\\\\.\\pipe\\')
      format-list -inputobject ($pipes -replace '\\\\', '/' )
    EOF
    ) do
      named_pipes.each do |named_pipe|
        its (:stdout) { should contain named_pipe }
      end
    end
  end
  # TODO:
  # https://chromium.googlesource.com/chromium/src/+/master/mojo/public/cpp/platform/README.md
  # //./pipe/mojo.3684.5972.3468193222387870433
end
