$DebugPreference = 'Continue'
# NOTE: process management needed to run elevated
# based on: http://www.cyberforum.ru/powershell/thread1719005.html
# see also e.g. https://github.com/rgl/customize-windows-vagrant
if (-not (New-Object Security.Principal.WindowsPrincipal(
  [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
  exit 0
}

$appRegPath =  '/SOFTWARE/Microsoft/Windows/CurrentVersion/App Paths'

$data = @{}
pushd HKLM:
cd $appRegPath
$apps = get-childitem . | select-object -property name;
$apps| foreach-object {

  $app = $_

  pushd $appRegPath
  $path = (($app.'name') -replace 'HKEY_LOCAL_MACHINE' , '') -replace '^.*(?:\\|/)', ''
  # write-debug  "Get-ItemProperty -path ${path} -name '(default)'"
  try {
    $appPath = Get-ItemProperty -path $path -name '(default)' -errorAction stop
  } catch [Exception] {
    write-error (($_.Exception.Message) -split "`n")[0]
    # Get-ItemProperty : Property (default) does not exist at path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\cmmgr32.exe.
  }
  if ($appPath -ne $null) {
    $data.add(($path -replace '\..*$', '' ), $appPath.'(default)')
  }
  popd
}
popd

if ($DebugPreference -eq 'Continue') {
  format-list -InputObject $data
}
$data.keys | foreach-object {
  $app = $_
  $path = $data[$app]
  # NOTE: starting processes is unreliable due to UAC
  start-process  cmd.exe -argumentlist @('/c', 'start' , $app )
  start-sleep -seconds 5
  $result = get-process | where-object { $_.ProcessName -match $app } | select-object -Property id,path
  if ($result -ne $null) {
    # write-debug : Cannot bind argument to parameter 'Message' because it is null.
    if ($DebugPreference -eq 'Continue') {
      format-list -InputObject $result
    }
    $id = $result.'id'
    # TODO: assertion
    if ($id -ne $null) {
      try {
        # write-debug ('Trying to terminate {0}' -f  $id)
        stop-process -id $id -force -erroraction stop
      } catch [Exception] {
        write-error (($_.Exception.Message) -split "`n")[0]
        # DEBUG: Cannot stop process "Defraggler (2004)" because of the following error: Access is denied
      }
    } else {
      write-error ('Failed to find process named {0}' -f $name)
    }
  }
}