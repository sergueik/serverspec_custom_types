require_relative '../windows_spec_helper'

context 'Inspecting netstat.exe command' do
  # The command below is the equivalent of a linux shell command
  # ps -p $(sudo netstat -oanpt | grep $connected_port|awk '{print $7}' | sed 's|/.*||')
  # NOTE: avoid $pid variable name in Powershell snippets
  oracle_port = 1521
  oracle_process = 'TNSLSNR'
  # with oracle we check commandline
  describe command (<<-EOF
    $o = invoke-expression -command 'cmd.exe /c netstat -ano -p TCP' ;
    $port = '#{oracle_port}'
    $p = ( $o |
      where-object  { $_ -match ":${port}" } |
        select-object -first 1 |
          foreach-object { $fields = $_.split(" ") ; write-output ('{0}' -f $fields[-1]) });
    write-output $p
    $r = get-CIMInstance win32_process |
      where-object { $_.Processid -eq  $p }
    write-output $r.commandLine
  EOF
  ) do
    its(:stdout) { should match /#{oracle_process}/io }
  end
  # with sshd we check process name
  ssh_port = 22
  ssh_process = 'sshd.exe'
  describe command (<<-EOF
    $o = invoke-expression -command 'cmd.exe /c netstat -ano -p TCP' ;
    $port = '#{ssh_port}'
    $p = ( $o |
      where-object  { $_ -match ":${port}" } |
        select-object -first 1 |
          foreach-object { $fields = $_.split(" ") ; write-output ('{0}' -f $fields[-1]) });
    write-output $p
    $r = get-CIMInstance win32_process |
      where-object { $_.Processid -eq  $p }
    write-output $r.name
  EOF
  ) do
    its(:stdout) { should match /#{ssh_process}/io }
  end
  # semicolon terminators added for readability - not strictly necessary
  # with a single capture expression, Matches.Value is also possible
  describe command (<<-EOF
    $o = & netstat.exe -ano -p TCP|where-object {$_ -match '0.0.0.0:22'};
    $o | where-object {$_ -match 'LISTENING *([0-9]+)' }  |out-null;
    $p = $Matches.1;
    $n = get-CIMInstance win32_process | where-object { $_.Processid -eq $p} | select-object -expandproperty Name;
    write-output $n;
  EOF
  ) do
    its(:stdout) { should contain 'sshd.exe' }
  end
end
