require_relative '../windows_spec_helper'
# Copyright (c) Serguei Kouzmine

context 'Binary architecture' do

  # based on: http://www.cyberforum.ru/powershell/thread1942421.html
  context 'p/invoke' do
    describe command(<<-EOF
  function Get-BinaryType {
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({test-path $_})]
    [String]$path
  )

  begin {
    # https://msdn.microsoft.com/en-us/library/ch9714z3(v=vs.110).aspx
    # https://msdn.microsoft.com/en-us/library/k2w5ey1e(v=vs.110).aspx
    # https://msdn.microsoft.com/en-us/library/system.reflection.bindingflags(v=vs.110).aspx
    # http://www.gnu.org/software/dotgnu/pnetlib-doc/System/Reflection/BindingFlags.html
    # BindingFlags.Static | BindingFlags.NonPublic
    ($$ = [PSObject].Assembly.GetType('System.Management.Automation.NativeCommandProcessor')).GetFields([Reflection.BindingFlags] 40 ) |
      where-object {$_.Name -cmatch '\ASCS_'} |
      foreach-object {$bt = @{}}{ $bt[$_.GetValue($null)] = $_.Name }
      # http://www.pinvoke.net/default.aspx/kernel32.getbinarytype
      $GetBinaryType = $$.GetMethod('GetBinaryTypeA', [Reflection.BindingFlags] 40 )

      $path = convert-path $path
      [Int32]$bintype = 0
    }
    process {
      if (0 -eq $GetBinaryType.Invoke($null, ( $par = [Object[]]@($Path, $bintype)))) {
        throw ((New-Object ComponentModel.Win32Exception( [Runtime.InteropServices.Marshal]::GetLastWin32Error())).Message -replace '%1', $Path)
      }
      write-error 'xxx'
      $bt[$par[1]]
    }
    end {}
  }
  start-sleep -milliseconds 1000
  $res = get-binaryType -path 'c:\\windows\\notepad.exe'
  write-output ('result : {0}' -f $res) | tee-object $env:temp\\a.txt
EOF
    ) do
      # TODO: how to get the output ? SCS_32BIT_BINARY
      # Preparing modules for first use.
      #< CLIXML <Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj S="progress" RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj></Objs>
      its(:stdout) { should contain 'SCS_32BIT_BINARY' }
      its(:stderr) { should contain 'xxx' }
    end
  end
end

