require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

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
    # https://rkeithhill.wordpress.com/2014/11/01/windows-powershell-and-named-pipes/
    # https://manual.audacityteam.org/man/scripting_reference.html
    describe command(<<-EOF
      param(
        [String]$command = 'Help: Command=Help'
      )
      $pipe_out = new-object System.IO.Pipes.NamedPipeClientStream('.', 'ToSrvPipe', [System.IO.Pipes.PipeDirection]::Out)
      $pipe_out.Connect()
      $pipe_writer = new-object System.IO.StreamWriter($pipe_out)
      $pipe_writer.AutoFlush = $true

      $pipe_in = new-object System.IO.Pipes.NamedPipeClientStream('.', 'FromSrvPipe', [System.IO.Pipes.PipeDirection]::In)
      $pipe_in.Connect()
      $pipe_reader = new-object System.IO.StreamReader($pipe_in)

      $pipe_writer.WriteLine($command)
      while ($true) {
        $result = $pipe_reader.Readline()
        if ($result -eq $null -or $result -eq '') {
          if ($has_result) {
             break;
          }
        } else {
          write-output $result
          $has_result = $true
        }
      }

      $pipe_in.Dispose()
      $pipe_out.Dispose()
    EOF
    ) do
      its (:stdout) { should contain 'Gives help on a command' }
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
# https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/finding-powershell-named-pipes
# reauies Windows 8.1 and Powershell 5.0
Get-ChildItem -Path "\\.\pipe\" -Filter '*demo*' |
ForEach-Object {
    Get-Process -Id $_.Name.Split('.')[2]
}
