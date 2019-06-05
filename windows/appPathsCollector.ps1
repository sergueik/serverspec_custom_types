
# based on: http://www.cyberforum.ru/powershell/thread1719005.html
function Get-Win32Error([Int32]$e) {
  [PSObject].Assembly.GetType(
    'Microsoft.PowerShell.Commands.Internal.Win32Native'
  ).GetMethod(
    'GetMessage', [Reflection.BindingFlags]40
  ).Invoke($null, @($e))
}


# NOTE: process management needed to run elevated
# see also e.g. https://github.com/rgl/customize-windows-vagrant
if ((New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
  # The access code is invalid.
  Get-Win32Error 12 
} else {
  exit 0
}
    
$rootPath =  '\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths'

$appPathsData = @{}
pushd HKLM:
cd $rootPath
$appPaths = get-childitem . | select-object -property name;
$appPaths| foreach-object {

  $appPAth = $_

  pushd $rootPath
  $path = (($appPath.'name') -replace 'HKEY_LOCAL_MACHINE' , '') -replace '^.*\\', ''
  write-debug  "Get-ItemProperty -path ${path} -name '(default)'"
  try {
    $data = Get-ItemProperty -path $path -name '(default)' -errorAction stop
  } catch [Exception] {
    write-debug (($_.Exception.Message) -split "`n")[0]
    # DEBUG: Cannot stop process "Defraggler (2004)" because of the following error:
    # Access is denied
  }
  if ($data -ne $null) {
    $appPathsData.add(($path -replace '\..*$', '' ), $data.'(default)')
  }
  popd
}
popd
c:
#
# if ($DebugPreference -eq 'Continue') {
#   write-debug $appPathsData
# }
$appPathsData.keys | foreach-object {
  $name = $_
  $path = $appPathsData[$name]
  # NOTE: unreliable due to UAC
  start-process  cmd.exe -argumentlist @('/c', 'start' , $name )
  start-sleep -seconds 10
  $result = get-process | where-object { $_.ProcessName -match $name } | select-object -Property id,path
  if ($result -ne $null) {
    # write-debug : Cannot bind argument to parameter 'Message' because it is null.
    write-debug $result
    $id = $result.'id'
    # TODO: assertion
    if ($id -ne $null) {
      try {
        write-debug ('Trying to terminate {0}' -f  $id)
        stop-process -id $id -force -erroraction stop
      } catch [Exception] {
        write-debug (($_.Exception.Message) -split "`n")[0]
        # e.g.
        # Get-ItemProperty : Property (default) does not exist at path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cmmgr32.exe.
      }
    } else {
      write-debug ('Failed to find process named {0}' -f $name)
    }
  }
}